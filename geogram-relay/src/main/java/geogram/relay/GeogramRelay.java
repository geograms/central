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

        // Serve www collection from device - direct callsign access
        app.get("/{callsign}", ctx -> handleWwwCollectionRequest(ctx, ""));
        app.get("/{callsign}/", ctx -> handleWwwCollectionRequest(ctx, "/"));
        app.get("/{callsign}/*", ctx -> handleWwwCollectionRequest(ctx, null));

        // Root endpoint - Status API
        app.get("/", ctx -> {
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
                ctx.result(response.responseBody);
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
                ctx.result(response.responseBody);
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
}

