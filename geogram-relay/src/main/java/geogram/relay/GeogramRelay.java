/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import io.javalin.Javalin;
import io.javalin.http.Context;
import io.javalin.community.ssl.SslPlugin;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.Base64;

/**
 * Geogram Relay Server - WebSocket/HTTP proxy for device access
 *
 * Main entry point that sets up Javalin server with WebSocket and HTTP endpoints
 *
 * @author brito
 */
public class GeogramRelay {

    private static final Logger LOG = LoggerFactory.getLogger(GeogramRelay.class);
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    private static RelayServer relayServer;
    private static Config config;
    private static AprsClient aprsClient;
    private static LogManager logManager;

    public static void main(String[] args) {
        LOG.info("Starting Geogram Relay Server...");

        // Start log manager
        logManager = new LogManager();
        logManager.start();
        logManager.log("Geogram Relay Server starting...");

        // Load configuration
        config = Config.load();

        // Command line port override
        if (args.length > 0) {
            try {
                config.port = Integer.parseInt(args[0]);
                LOG.info("Port overridden from command line: {}", config.port);
            } catch (NumberFormatException e) {
                LOG.error("Invalid port number: {}", args[0]);
                System.exit(1);
                return; // Never reached but needed for compilation
            }
        }

        // Validate configuration
        if (!config.validate()) {
            LOG.error("Invalid configuration, exiting");
            System.exit(1);
            return;
        }

        LOG.info("Using configuration: {}", config);

        // Initialize relay server
        relayServer = new RelayServer(config);

        // Initialize APRS client
        aprsClient = new AprsClient(config);
        aprsClient.start();

        // Create Javalin app
        Javalin app = Javalin.create(javalinConfig -> {
            javalinConfig.showJavalinBanner = false;
            javalinConfig.http.prefer405over404 = true;

            // Configure SSL if enabled
            if (config.enableSsl) {
                SslPlugin sslPlugin = new SslPlugin(sslConfig -> {
                    sslConfig.keystoreFromPath(config.keystorePath, config.keystorePassword);
                    sslConfig.insecure = false;  // Disable HTTP connector
                    sslConfig.secure = true;     // Enable HTTPS connector
                    sslConfig.securePort = config.port;
                    sslConfig.http2 = false;     // Disable HTTP/2 to avoid ALPN issues
                    sslConfig.sniHostCheck = false; // Disable SNI check for self-signed certs
                });
                javalinConfig.registerPlugin(sslPlugin);
                LOG.info("SSL/TLS enabled with keystore: {}", config.keystorePath);
            }

            // Configure Gson as JSON mapper
            javalinConfig.jsonMapper(new io.javalin.json.JsonMapper() {
                @Override
                public String toJsonString(Object obj, java.lang.reflect.Type type) {
                    return GSON.toJson(obj, type);
                }

                @Override
                public <T> T fromJsonString(String json, java.lang.reflect.Type targetType) {
                    return GSON.fromJson(json, targetType);
                }
            });

            // Enable CORS if configured
            if (config.enableCors) {
                javalinConfig.bundledPlugins.enableCors(cors -> {
                    cors.addRule(rule -> {
                        if (config.corsAllowedOrigins.equals("*")) {
                            rule.anyHost();
                        } else {
                            String[] origins = config.corsAllowedOrigins.split(",");
                            for (String origin : origins) {
                                rule.allowHost(origin.trim());
                            }
                        }
                    });
                });
            }
        }).start(config.enableSsl ? -1 : config.port);

        // WebSocket endpoint for device connections
        app.ws("/", ws -> {
            ws.onConnect(ctx -> {
                // Increase max message size to 10MB for large collection transfers
                ctx.session.setMaxTextMessageSize(10 * 1024 * 1024); // 10MB
                ctx.session.setMaxBinaryMessageSize(10 * 1024 * 1024); // 10MB
                relayServer.onConnect(ctx);
            });
            ws.onMessage(ctx -> relayServer.onMessage(ctx));
            ws.onClose(ctx -> relayServer.onClose(ctx));
            ws.onError(ctx -> relayServer.onError(ctx, ctx.error()));
        });

        // HTTP endpoints

        // Get relay status - list all connected devices
        app.get("/relay/status", ctx -> {
            Collection<DeviceConnection> devices = relayServer.getDevices();

            Map<String, Object> response = new HashMap<>();
            response.put("connected_devices", devices.size());

            List<Map<String, Object>> deviceList = new ArrayList<>();
            for (DeviceConnection device : devices) {
                Map<String, Object> deviceInfo = new HashMap<>();
                deviceInfo.put("callsign", device.getCallsign());
                deviceInfo.put("uptime_seconds", device.getUptimeSeconds());
                deviceInfo.put("idle_seconds", device.getIdleSeconds());
                deviceInfo.put("connected_at", device.getConnectedAt());
                deviceList.add(deviceInfo);
            }
            response.put("devices", deviceList);

            ctx.json(response);
        });

        // Search collections endpoint
        app.get("/search", ctx -> {
            String query = ctx.queryParam("q");
            String limitParam = ctx.queryParam("limit");

            if (query == null || query.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Missing query parameter 'q'");
                ctx.status(400).json(error);
                return;
            }

            int limit = 50; // Default limit
            if (limitParam != null) {
                try {
                    limit = Integer.parseInt(limitParam);
                    if (limit < 1 || limit > 500) {
                        limit = 50;
                    }
                } catch (NumberFormatException e) {
                    limit = 50;
                }
            }

            List<SearchResult> results = relayServer.searchCollections(query, limit);

            Map<String, Object> response = new HashMap<>();
            response.put("query", query);
            response.put("total_results", results.size());
            response.put("limit", limit);
            response.put("results", results);

            ctx.json(response);
        });

        // Get device info
        app.get("/device/{callsign}", ctx -> {
            String callsign = ctx.pathParam("callsign").toUpperCase();
            DeviceConnection device = relayServer.getDevice(callsign);

            Map<String, Object> response = new HashMap<>();
            response.put("callsign", callsign);

            if (device != null) {
                response.put("connected", true);
                response.put("uptime", device.getUptimeSeconds());
                response.put("idleTime", device.getIdleSeconds());
                ctx.json(response);
            } else {
                response.put("connected", false);
                response.put("error", "Device not connected");
                ctx.status(404).json(response);
            }
        });

        // Proxy HTTP request to device - support all HTTP methods
        app.get("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.post("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.put("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.delete("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.patch("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.head("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));
        app.options("/device/{callsign}/*", ctx -> handleDeviceRequest(ctx));

        // API status endpoint
        app.get("/api/status", ctx -> {
            long uptimeMs = System.currentTimeMillis() - relayServer.getStartTime();
            long uptimeHours = uptimeMs / (1000 * 60 * 60);  // Convert to hours

            // Get server start time in ISO format
            java.time.Instant startInstant = java.time.Instant.ofEpochMilli(relayServer.getStartTime());
            String startedAt = startInstant.toString();

            Map<String, Object> info = new HashMap<>();
            info.put("service", "Geogram Relay Server");
            info.put("version", "1.0.0");
            info.put("status", "online");
            info.put("started_at", startedAt);
            info.put("uptime_hours", uptimeHours);
            info.put("port", config.port);

            // Server description
            info.put("description", config.serverDescription != null ?
                config.serverDescription : "Geogram relay server for amateur radio operations");

            // Connected devices information
            Collection<DeviceConnection> devices = relayServer.getDevices();
            info.put("connected_devices", devices.size());
            info.put("max_devices", config.maxConnectedDevices);

            // Device list with details
            List<Map<String, Object>> deviceList = new ArrayList<>();
            for (DeviceConnection device : devices) {
                Map<String, Object> deviceInfo = new HashMap<>();
                deviceInfo.put("callsign", device.getCallsign());
                deviceInfo.put("uptime_seconds", device.getUptimeSeconds());
                deviceInfo.put("idle_seconds", device.getIdleSeconds());
                deviceInfo.put("connected_at", device.getConnectedAt());
                deviceList.add(deviceInfo);
            }
            info.put("devices", deviceList);

            // Location/coordinates information
            Map<String, Object> location = new HashMap<>();
            location.put("latitude", config.latitude);
            location.put("longitude", config.longitude);
            location.put("city", config.city);
            location.put("region", config.region);
            location.put("country", config.country);
            location.put("country_code", config.countryCode);
            location.put("timezone", config.timezone);
            location.put("ip", config.serverIp);
            location.put("isp", config.isp);
            info.put("location", location);

            ctx.json(info);
        });

        // Serve www collection from device - direct callsign access
        app.get("/{callsign}", ctx -> handleWwwCollectionRequest(ctx, ""));
        app.get("/{callsign}/", ctx -> handleWwwCollectionRequest(ctx, "/"));
        app.get("/{callsign}/*", ctx -> handleWwwCollectionRequest(ctx, null));

        // Root endpoint - HTML Interface
        app.get("/", ctx -> {
            ctx.contentType("text/html");
            ctx.result(getRelayHomePage());
        });

        // Legacy root status (for backward compatibility)
        app.get("/status", ctx -> {
            long uptimeMs = System.currentTimeMillis() - relayServer.getStartTime();
            long uptimeHours = uptimeMs / (1000 * 60 * 60);  // Convert to hours

            // Get server start time in ISO format
            java.time.Instant startInstant = java.time.Instant.ofEpochMilli(relayServer.getStartTime());
            String startedAt = startInstant.toString();

            Map<String, Object> info = new HashMap<>();
            info.put("service", "Geogram Relay Server");
            info.put("version", "1.0.0");
            info.put("status", "online");
            info.put("started_at", startedAt);
            info.put("uptime_hours", uptimeHours);
            info.put("port", config.port);

            // Server description
            info.put("description", config.serverDescription != null ?
                config.serverDescription : "Geogram relay server for amateur radio operations");

            // Connected devices information
            Collection<DeviceConnection> devices = relayServer.getDevices();
            info.put("connected_devices", devices.size());
            info.put("max_devices", config.maxConnectedDevices);

            // Device list with details
            List<Map<String, Object>> deviceList = new ArrayList<>();
            for (DeviceConnection device : devices) {
                Map<String, Object> deviceInfo = new HashMap<>();
                deviceInfo.put("callsign", device.getCallsign());
                deviceInfo.put("uptime_seconds", device.getUptimeSeconds());
                deviceInfo.put("idle_seconds", device.getIdleSeconds());
                deviceInfo.put("connected_at", device.getConnectedAt());
                deviceList.add(deviceInfo);
            }
            info.put("devices", deviceList);

            // Location/coordinates information
            Map<String, Object> location = new HashMap<>();
            location.put("latitude", config.latitude);
            location.put("longitude", config.longitude);
            location.put("city", config.city);
            location.put("region", config.region);
            location.put("country", config.country);
            location.put("country_code", config.countryCode);
            location.put("timezone", config.timezone);
            location.put("ip", config.serverIp);
            location.put("isp", config.isp);
            info.put("location", location);

            ctx.json(info);
        });

        // Exception handlers
        app.exception(Exception.class, (e, ctx) -> {
            LOG.error("Unhandled exception", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            ctx.status(500).json(error);
        });

        // Shutdown hook
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            LOG.info("Shutting down Geogram Relay Server...");
            if (logManager != null) {
                logManager.log("Server shutting down...");
            }
            app.stop();
            relayServer.shutdown();
            if (aprsClient != null) {
                aprsClient.stop();
            }
            if (logManager != null) {
                logManager.stop();
            }
            LOG.info("Server stopped");
        }));

        String protocol = config.enableSsl ? "https" : "http";
        String wsProtocol = config.enableSsl ? "wss" : "ws";
        String host = config.host.equals("0.0.0.0") ? "localhost" : config.host;

        LOG.info("Geogram Relay Server started on {}:{}", config.host, config.port);
        LOG.info("WebSocket endpoint: {}://{}:{}/", wsProtocol, host, config.port);
        LOG.info("HTTP endpoints:");
        LOG.info("  GET  {}://{}:{}/relay/status - List connected devices", protocol, host, config.port);
        LOG.info("  GET  {}://{}:{}/search?q=<query>&limit=<n> - Search collections", protocol, host, config.port);
        LOG.info("  GET  {}://{}:{}/device/{{callsign}} - Get device info", protocol, host, config.port);
        LOG.info("  ANY  {}://{}:{}/device/{{callsign}}/{{path}} - Proxy to device", protocol, host, config.port);
        LOG.info("  GET  {}://{}:{}/{{callsign}} - Serve www collection from device", protocol, host, config.port);
        LOG.info("  GET  {}://{}:{}/{{callsign}}/{{path}} - Serve file from www collection", protocol, host, config.port);
        LOG.info("Configuration file: config.json");
        LOG.info("Server location: {}, {} (lat: {}, lon: {})",
                config.city, config.country,
                String.format("%.4f", config.latitude),
                String.format("%.4f", config.longitude));
        LOG.info("Log file: {}", logManager.getCurrentLogFilePath());

        // Log startup to file
        logManager.log(String.format("Server started on %s:%d", config.host, config.port));
        logManager.log(String.format("Location: %s, %s", config.city, config.country));
        logManager.log(String.format("APRS: %s (callsign: %s)",
            config.enableAprs ? "enabled" : "disabled", config.aprsCallsign));
    }

    /**
     * Get log manager for logging events
     */
    public static LogManager getLogManager() {
        return logManager;
    }

    /**
     * Format uptime in human-readable format
     */
    private static String formatUptime(long seconds) {
        long days = seconds / 86400;
        long hours = (seconds % 86400) / 3600;
        long minutes = (seconds % 3600) / 60;
        long secs = seconds % 60;

        if (days > 0) {
            return String.format("%dd %dh %dm %ds", days, hours, minutes, secs);
        } else if (hours > 0) {
            return String.format("%dh %dm %ds", hours, minutes, secs);
        } else if (minutes > 0) {
            return String.format("%dm %ds", minutes, secs);
        } else {
            return String.format("%ds", secs);
        }
    }

    /**
     * Handle www collection request - serve static files from device's www collection
     */
    private static void handleWwwCollectionRequest(Context ctx, String pathOverride) {
        String callsign = ctx.pathParam("callsign").toUpperCase();
        LOG.info("WWW collection request for callsign: {}", callsign);

        // Validate callsign format to avoid conflicts with API paths
        if (!isValidCallsign(callsign)) {
            // Not a valid callsign, let it fall through to other handlers
            LOG.warn("Invalid callsign format: {}", callsign);
            ctx.status(404).result("Not found");
            return;
        }

        LOG.debug("Callsign validation passed for: {}", callsign);

        // Check if device is connected
        DeviceConnection device = relayServer.getDevice(callsign);
        LOG.info("Device lookup for {}: {}", callsign, device != null ? "FOUND" : "NOT FOUND");

        if (device == null) {
            // Log all connected devices for debugging
            Collection<DeviceConnection> allDevices = relayServer.getDevices();
            LOG.warn("Device {} not found. Connected devices ({}):", callsign, allDevices.size());
            for (DeviceConnection d : allDevices) {
                LOG.warn("  - {}", d.getCallsign());
            }

            Map<String, String> error = new HashMap<>();
            error.put("error", "Device not connected");
            error.put("callsign", callsign);
            ctx.status(503).json(error);
            return;
        }

        // Determine the file path within the www collection
        String filePath;
        if (pathOverride != null) {
            filePath = pathOverride;
        } else {
            // Extract path after /{callsign}/
            String[] parts = ctx.path().split("/", 3);
            filePath = parts.length > 2 ? "/" + parts[2] : "/";
        }

        // Default to index.html for root or directory paths
        if (filePath.equals("") || filePath.equals("/")) {
            filePath = "/index.html";
        }

        // Construct the collection path: /collections/www/{filePath}
        String collectionPath = "/collections/www" + filePath;

        // Generate request ID
        String requestId = UUID.randomUUID().toString();

        // Create minimal headers for the request
        Map<String, String> headers = new HashMap<>();
        headers.put("Accept", ctx.header("Accept") != null ? ctx.header("Accept") : "*/*");

        try {
            // Forward request to device
            PendingRequest pending = relayServer.forwardHttpRequest(
                    callsign, requestId, "GET", collectionPath, headers, "");

            // Wait for response with timeout
            RelayMessage response = pending.getResponseFuture()
                    .get(config.httpRequestTimeout, TimeUnit.SECONDS);

            // Send response to client
            ctx.status(response.statusCode);

            // Set response headers
            if (response.responseHeaders != null && !response.responseHeaders.isEmpty()) {
                try {
                    @SuppressWarnings("unchecked")
                    Map<String, String> responseHeaders = GSON.fromJson(
                            response.responseHeaders, Map.class);
                    responseHeaders.forEach((key, value) -> {
                        if (!key.equalsIgnoreCase("content-length")) {
                            ctx.header(key, value);
                        }
                    });
                } catch (Exception e) {
                    LOG.warn("Failed to parse response headers", e);
                }
            }

            // Send response body
            if (response.responseBody != null && !response.responseBody.isEmpty()) {
                if (response.isBase64 != null && response.isBase64) {
                    // Decode base64 before sending
                    byte[] decodedBytes = Base64.getDecoder().decode(response.responseBody);
                    ctx.result(decodedBytes);
                } else {
                    ctx.result(response.responseBody);
                }
            }

        } catch (TimeoutException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Request timeout");
            error.put("callsign", callsign);
            error.put("path", filePath);
            ctx.status(504).json(error);
        } catch (Exception e) {
            LOG.error("Error serving www collection", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "Proxy error: " + e.getMessage());
            error.put("callsign", callsign);
            error.put("path", filePath);
            ctx.status(502).json(error);
        }
    }

    /**
     * Validate callsign format - must match amateur radio callsign pattern
     */
    private static boolean isValidCallsign(String callsign) {
        // Check against known non-callsign paths first
        if (callsign.equalsIgnoreCase("relay") ||
            callsign.equalsIgnoreCase("search") ||
            callsign.equalsIgnoreCase("device") ||
            callsign.equalsIgnoreCase("api")) {
            LOG.debug("Callsign {} rejected - reserved word", callsign);
            return false;
        }

        // Validate against configured callsign pattern
        boolean matches = config.callsignPattern != null &&
               java.util.regex.Pattern.matches(config.callsignPattern, callsign);

        LOG.debug("Callsign {} validation against pattern '{}': {}",
                callsign, config.callsignPattern, matches);

        return matches;
    }

    /**
     * Handle HTTP request proxying to device
     */
    private static void handleDeviceRequest(Context ctx) {
        String callsign = ctx.pathParam("callsign").toUpperCase();
        String path = "/" + ctx.path().split("/", 4)[3]; // Extract path after /device/{callsign}

        // Check if device is connected
        DeviceConnection device = relayServer.getDevice(callsign);
        if (device == null) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Device not connected");
            error.put("callsign", callsign);
            ctx.status(503).json(error);
            return;
        }

        // Generate request ID
        String requestId = UUID.randomUUID().toString();

        // Extract headers
        Map<String, String> headers = new HashMap<>();
        ctx.headerMap().forEach((key, value) -> {
            if (!key.equalsIgnoreCase("host") &&
                !key.equalsIgnoreCase("connection")) {
                headers.put(key, value);
            }
        });

        // Get request body
        String body = ctx.body();

        try {
            // Forward request to device
            PendingRequest pending = relayServer.forwardHttpRequest(
                    callsign, requestId, ctx.method().name(), path, headers, body);

            // Wait for response with timeout
            RelayMessage response = pending.getResponseFuture()
                    .get(config.httpRequestTimeout, TimeUnit.SECONDS);

            // Send response to client
            ctx.status(response.statusCode);

            // Set response headers
            if (response.responseHeaders != null && !response.responseHeaders.isEmpty()) {
                try {
                    @SuppressWarnings("unchecked")
                    Map<String, String> responseHeaders = GSON.fromJson(
                            response.responseHeaders, Map.class);
                    responseHeaders.forEach((key, value) -> {
                        if (!key.equalsIgnoreCase("content-length")) {
                            ctx.header(key, value);
                        }
                    });
                } catch (Exception e) {
                    LOG.warn("Failed to parse response headers", e);
                }
            }

            // Send response body
            if (response.responseBody != null && !response.responseBody.isEmpty()) {
                if (response.isBase64 != null && response.isBase64) {
                    // Decode base64 before sending
                    byte[] decodedBytes = Base64.getDecoder().decode(response.responseBody);
                    ctx.result(decodedBytes);
                } else {
                    ctx.result(response.responseBody);
                }
            }

        } catch (TimeoutException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Request timeout");
            error.put("callsign", callsign);
            ctx.status(504).json(error);
        } catch (Exception e) {
            LOG.error("Error proxying request", e);
            Map<String, String> error = new HashMap<>();
            error.put("error", "Proxy error: " + e.getMessage());
            error.put("callsign", callsign);
            ctx.status(502).json(error);
        }
    }

    /**
     * Generate HTML home page for the relay
     */
    private static String getRelayHomePage() {
        return "<!DOCTYPE html>\n" +
            "<html lang=\"en\">\n" +
            "<head>\n" +
            "    <meta charset=\"UTF-8\">\n" +
            "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n" +
            "    <title>Geogram Relay Server</title>\n" +
            "    <style>\n" +
            "        * { margin: 0; padding: 0; box-sizing: border-box; }\n" +
            "        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: #f5f5f5; color: #333; line-height: 1.6; }\n" +
            "        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }\n" +
            "        header { background: #2c3e50; color: white; padding: 30px 0; margin-bottom: 30px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }\n" +
            "        h1 { font-size: 2.5em; margin-bottom: 10px; }\n" +
            "        .subtitle { opacity: 0.9; font-size: 1.1em; }\n" +
            "        .search-box { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 30px; }\n" +
            "        .search-input { width: 100%; padding: 15px; font-size: 1.1em; border: 2px solid #ddd; border-radius: 5px; transition: border-color 0.3s; }\n" +
            "        .search-input:focus { outline: none; border-color: #3498db; }\n" +
            "        .search-btn { background: #3498db; color: white; border: none; padding: 15px 30px; font-size: 1.1em; border-radius: 5px; cursor: pointer; margin-top: 15px; transition: background 0.3s; }\n" +
            "        .search-btn:hover { background: #2980b9; }\n" +
            "        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }\n" +
            "        .status-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }\n" +
            "        .status-card h3 { color: #2c3e50; margin-bottom: 10px; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }\n" +
            "        .status-card .value { font-size: 2em; font-weight: bold; color: #3498db; }\n" +
            "        .device-list { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 30px; }\n" +
            "        .device-list h2 { color: #2c3e50; margin-bottom: 20px; }\n" +
            "        .device-item { padding: 15px; border-bottom: 1px solid #eee; cursor: pointer; transition: background 0.2s; }\n" +
            "        .device-item:hover { background: #f8f9fa; }\n" +
            "        .device-item:last-child { border-bottom: none; }\n" +
            "        .device-callsign { font-size: 1.3em; font-weight: bold; color: #2c3e50; margin-bottom: 5px; }\n" +
            "        .device-info { color: #666; font-size: 0.9em; }\n" +
            "        .device-link { color: #3498db; text-decoration: none; }\n" +
            "        .device-link:hover { text-decoration: underline; }\n" +
            "        .search-results { background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); display: none; }\n" +
            "        .search-results h2 { color: #2c3e50; margin-bottom: 20px; }\n" +
            "        .result-item { padding: 15px; border-bottom: 1px solid #eee; }\n" +
            "        .result-item:last-child { border-bottom: none; }\n" +
            "        .result-title { font-weight: bold; color: #2c3e50; margin-bottom: 5px; }\n" +
            "        .result-path { color: #666; font-size: 0.9em; }\n" +
            "        .loading { text-align: center; padding: 20px; color: #666; }\n" +
            "        .error { background: #fee; color: #c33; padding: 15px; border-radius: 5px; margin: 20px 0; }\n" +
            "    </style>\n" +
            "</head>\n" +
            "<body>\n" +
            "    <header>\n" +
            "        <div class=\"container\">\n" +
            "            <h1>Geogram Relay Server</h1>\n" +
            "            <div class=\"subtitle\">Search and browse collections from connected devices</div>\n" +
            "        </div>\n" +
            "    </header>\n" +
            "\n" +
            "    <div class=\"container\">\n" +
            "        <div class=\"search-box\">\n" +
            "            <h2 style=\"margin-bottom: 15px; color: #2c3e50;\">Search Collections</h2>\n" +
            "            <input type=\"text\" id=\"searchInput\" class=\"search-input\" placeholder=\"Search for files in all connected devices...\" />\n" +
            "            <button class=\"search-btn\" onclick=\"performSearch()\">Search</button>\n" +
            "        </div>\n" +
            "\n" +
            "        <div class=\"status-grid\" id=\"statusGrid\">\n" +
            "            <div class=\"status-card\">\n" +
            "                <h3>Status</h3>\n" +
            "                <div class=\"value\" id=\"statusValue\">Loading...</div>\n" +
            "            </div>\n" +
            "            <div class=\"status-card\">\n" +
            "                <h3>Connected Devices</h3>\n" +
            "                <div class=\"value\" id=\"devicesValue\">-</div>\n" +
            "            </div>\n" +
            "            <div class=\"status-card\">\n" +
            "                <h3>Uptime</h3>\n" +
            "                <div class=\"value\" id=\"uptimeValue\">-</div>\n" +
            "            </div>\n" +
            "            <div class=\"status-card\">\n" +
            "                <h3>Server</h3>\n" +
            "                <div class=\"value\" style=\"font-size: 1.2em;\" id=\"serverValue\">-</div>\n" +
            "            </div>\n" +
            "        </div>\n" +
            "\n" +
            "        <div class=\"device-list\" id=\"deviceList\">\n" +
            "            <h2>Connected Devices</h2>\n" +
            "            <div class=\"loading\">Loading devices...</div>\n" +
            "        </div>\n" +
            "\n" +
            "        <div class=\"search-results\" id=\"searchResults\">\n" +
            "            <h2>Search Results</h2>\n" +
            "            <div id=\"resultsContent\"></div>\n" +
            "        </div>\n" +
            "    </div>\n" +
            "\n" +
            "    <script>\n" +
            "        async function loadStatus() {\n" +
            "            try {\n" +
            "                const response = await fetch('/api/status');\n" +
            "                const data = await response.json();\n" +
            "                \n" +
            "                document.getElementById('statusValue').textContent = data.status.toUpperCase();\n" +
            "                document.getElementById('devicesValue').textContent = data.connected_devices;\n" +
            "                document.getElementById('uptimeValue').textContent = data.uptime_hours + 'h';\n" +
            "                document.getElementById('serverValue').textContent = data.location.city || 'Unknown';\n" +
            "                \n" +
            "                const deviceList = document.getElementById('deviceList');\n" +
            "                if (data.devices && data.devices.length > 0) {\n" +
            "                    deviceList.innerHTML = '<h2>Connected Devices</h2>' + \n" +
            "                        data.devices.map(device => `\n" +
            "                            <div class=\"device-item\">\n" +
            "                                <div class=\"device-callsign\">\n" +
            "                                    <a href=\"/${device.callsign}\" class=\"device-link\" target=\"_blank\">${device.callsign}</a>\n" +
            "                                </div>\n" +
            "                                <div class=\"device-info\">Connected ${formatTime(device.uptime_seconds)} ago</div>\n" +
            "                            </div>\n" +
            "                        `).join('');\n" +
            "                } else {\n" +
            "                    deviceList.innerHTML = '<h2>Connected Devices</h2><div class=\"loading\">No devices connected</div>';\n" +
            "                }\n" +
            "            } catch (error) {\n" +
            "                console.error('Error loading status:', error);\n" +
            "                document.getElementById('statusValue').textContent = 'ERROR';\n" +
            "            }\n" +
            "        }\n" +
            "\n" +
            "        async function performSearch() {\n" +
            "            const query = document.getElementById('searchInput').value.trim();\n" +
            "            if (!query) return;\n" +
            "            \n" +
            "            const resultsDiv = document.getElementById('searchResults');\n" +
            "            const resultsContent = document.getElementById('resultsContent');\n" +
            "            resultsDiv.style.display = 'block';\n" +
            "            resultsContent.innerHTML = '<div class=\"loading\">Searching...</div>';\n" +
            "            \n" +
            "            try {\n" +
            "                const response = await fetch(`/search?q=${encodeURIComponent(query)}`);\n" +
            "                const data = await response.json();\n" +
            "                \n" +
            "                if (data.results && data.results.length > 0) {\n" +
            "                    resultsContent.innerHTML = data.results.map(result => `\n" +
            "                        <div class=\"result-item\">\n" +
            "                            <div class=\"result-title\">${result.fileName || result.name}</div>\n" +
            "                            <div class=\"result-path\">${result.collectionName} - ${result.deviceCallsign}</div>\n" +
            "                        </div>\n" +
            "                    `).join('');\n" +
            "                } else {\n" +
            "                    resultsContent.innerHTML = '<div class=\"loading\">No results found</div>';\n" +
            "                }\n" +
            "            } catch (error) {\n" +
            "                console.error('Search error:', error);\n" +
            "                resultsContent.innerHTML = '<div class=\"error\">Error performing search</div>';\n" +
            "            }\n" +
            "        }\n" +
            "\n" +
            "        document.getElementById('searchInput').addEventListener('keypress', function(e) {\n" +
            "            if (e.key === 'Enter') performSearch();\n" +
            "        });\n" +
            "\n" +
            "        function formatTime(seconds) {\n" +
            "            if (seconds < 60) return seconds + ' seconds';\n" +
            "            if (seconds < 3600) return Math.floor(seconds / 60) + ' minutes';\n" +
            "            if (seconds < 86400) return Math.floor(seconds / 3600) + ' hours';\n" +
            "            return Math.floor(seconds / 86400) + ' days';\n" +
            "        }\n" +
            "\n" +
            "        // Load status on page load\n" +
            "        loadStatus();\n" +
            "        // Refresh status every 30 seconds\n" +
            "        setInterval(loadStatus, 30000);\n" +
            "    </script>\n" +
            "</body>\n" +
            "</html>";\n" +
            "    }\n" +
            "}

