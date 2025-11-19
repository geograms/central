/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import io.javalin.websocket.WsContext;
import io.javalin.websocket.WsMessageContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.regex.Pattern;

/**
 * Relay server managing WebSocket connections and request routing
 *
 * @author brito
 */
public class RelayServer {

    private static final Logger LOG = LoggerFactory.getLogger(RelayServer.class);

    private final Config config;
    private final long startTime;

    // Callsign validation pattern
    private Pattern callsignPattern;

    // Connected devices: callsign -> DeviceConnection
    private final Map<String, DeviceConnection> devices = new ConcurrentHashMap<>();

    // Pending HTTP requests: requestId -> PendingRequest
    private final Map<String, PendingRequest> pendingRequests = new ConcurrentHashMap<>();

    // WebSocket context to callsign mapping
    private final Map<WsContext, String> contextToCallsign = new ConcurrentHashMap<>();

    // Cleanup scheduler
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    public RelayServer(Config config) {
        this.config = config;
        this.startTime = System.currentTimeMillis();
        this.callsignPattern = Pattern.compile(config.callsignPattern);

        // Schedule periodic cleanup
        scheduler.scheduleAtFixedRate(this::cleanup, config.cleanupInterval,
                config.cleanupInterval, TimeUnit.SECONDS);
        LOG.info("Relay server initialized with config: {}", config);
    }

    public long getStartTime() {
        return startTime;
    }

    /**
     * Handle new WebSocket connection
     */
    public void onConnect(WsContext ctx) {
        LOG.info("WebSocket connection from {}", ctx.session.getRemoteAddress());
    }

    /**
     * Handle incoming WebSocket message
     */
    public void onMessage(WsMessageContext ctx) {
        try {
            String json = ctx.message();

            // First, check if it's a hello message (uses different format)
            com.google.gson.JsonObject jsonObj = new com.google.gson.JsonParser().parse(json).getAsJsonObject();
            String messageType = jsonObj.has("type") ? jsonObj.get("type").getAsString() : null;

            if ("hello".equals(messageType)) {
                handleHello(ctx, jsonObj);
                return;
            }

            // Parse as standard RelayMessage
            RelayMessage message = RelayMessage.fromJson(json);

            LOG.debug("Received message: type={}, requestId={}, callsign={}",
                    message.type, message.requestId, message.callsign);

            switch (message.type) {
                case RelayMessage.TYPE_REGISTER:
                    handleRegister(ctx, message);
                    break;
                case RelayMessage.TYPE_HTTP_RESPONSE:
                    handleHttpResponse(ctx, message);
                    break;
                case RelayMessage.TYPE_PING:
                    handlePing(ctx);
                    break;
                case RelayMessage.TYPE_COLLECTIONS_RESPONSE:
                    handleCollectionsResponse(ctx, message);
                    break;
                case RelayMessage.TYPE_COLLECTION_FILE_RESPONSE:
                    handleCollectionFileResponse(ctx, message);
                    break;
                default:
                    LOG.warn("Unknown message type: {}", message.type);
                    sendError(ctx, "Unknown message type: " + message.type);
            }
        } catch (Exception e) {
            LOG.error("Error processing message", e);
            sendError(ctx, "Invalid message format: " + e.getMessage());
        }
    }

    /**
     * Handle WebSocket connection close
     */
    public void onClose(WsContext ctx) {
        String callsign = contextToCallsign.remove(ctx);
        if (callsign != null) {
            DeviceConnection device = devices.remove(callsign);
            if (device != null) {
                LOG.info("Device disconnected: {}", callsign);

                // Log to file
                LogManager logManager = GeogramRelay.getLogManager();
                if (logManager != null) {
                    long uptime = device.getUptimeSeconds();
                    logManager.log(String.format("DEVICE_DISCONNECT: %s (uptime: %ds)", callsign, uptime));
                }

                // Fail all pending requests for this device
                failPendingRequestsForDevice(callsign);
            }
        }
    }

    /**
     * Handle WebSocket error
     */
    public void onError(WsContext ctx, Throwable error) {
        LOG.error("WebSocket error for {}", ctx.session.getRemoteAddress(), error);
        onClose(ctx);
    }

    /**
     * Handle HELLO message (Nostr-style introduction)
     */
    private void handleHello(WsContext ctx, com.google.gson.JsonObject jsonObj) {
        try {
            LOG.info("══════════════════════════════════════");
            LOG.info("HELLO MESSAGE RECEIVED");
            LOG.info("══════════════════════════════════════");
            LOG.info("From: {}", ctx.session.getRemoteAddress());

            // Extract event from message
            if (!jsonObj.has("event")) {
                LOG.warn("Hello message missing 'event' field");
                sendHelloAck(ctx, false, "Missing event field");
                return;
            }

            com.google.gson.JsonObject event = jsonObj.getAsJsonObject("event");

            // Extract fields
            String pubkey = event.has("pubkey") ? event.get("pubkey").getAsString() : null;
            String eventId = event.has("id") ? event.get("id").getAsString() : null;
            String sig = event.has("sig") ? event.get("sig").getAsString() : null;
            String content = event.has("content") ? event.get("content").getAsString() : null;

            LOG.info("Event ID: {}", eventId != null ? eventId.substring(0, Math.min(16, eventId.length())) + "..." : "null");
            LOG.info("Pubkey: {}", pubkey != null ? pubkey.substring(0, Math.min(16, pubkey.length())) + "..." : "null");
            LOG.info("Signature: {}", sig != null ? sig.substring(0, Math.min(16, sig.length())) + "..." : "null");
            LOG.info("Content: {}", content);

            // Extract callsign from tags
            String callsign = null;
            if (event.has("tags")) {
                com.google.gson.JsonArray tags = event.getAsJsonArray("tags");
                for (int i = 0; i < tags.size(); i++) {
                    com.google.gson.JsonArray tag = tags.get(i).getAsJsonArray();
                    if (tag.size() >= 2 && "callsign".equals(tag.get(0).getAsString())) {
                        callsign = tag.get(1).getAsString();
                        break;
                    }
                }
            }

            LOG.info("Callsign: {}", callsign);

            // Basic validation
            if (pubkey == null || eventId == null || sig == null) {
                LOG.warn("Hello message missing required fields");
                sendHelloAck(ctx, false, "Missing required fields (pubkey, id, or sig)");
                return;
            }

            if (callsign == null || callsign.isEmpty()) {
                LOG.warn("Hello message missing callsign tag");
                sendHelloAck(ctx, false, "Missing callsign tag");
                return;
            }

            // TODO: Verify signature using secp256k1
            // For now, accept all signatures and log warning
            LOG.warn("SIGNATURE NOT VERIFIED - Using simplified validation (to be upgraded to secp256k1)");

            // Create device storage directory
            String deviceStoragePath = createDeviceStorage(callsign);
            if (deviceStoragePath == null) {
                LOG.error("Failed to create device storage for {}", callsign);
                sendHelloAck(ctx, false, "Failed to create device storage");
                return;
            }

            // Store connection info
            contextToCallsign.put(ctx, callsign);

            // Convert pubkey to npub format (simplified - just prepend "npub1")
            String npub = pubkey.startsWith("npub1") ? pubkey : "npub1" + pubkey;

            // Register device connection
            DeviceConnection deviceConn = new DeviceConnection(callsign, npub, ctx, deviceStoragePath);
            devices.put(callsign, deviceConn);

            // Generate relay ID
            String relayId = "relay-" + System.currentTimeMillis();

            // Send success acknowledgment
            sendHelloAck(ctx, true, "Hello received and acknowledged", relayId);

            LOG.info("✓ HELLO ACKNOWLEDGED");
            LOG.info("Callsign: {}", callsign);
            LOG.info("Npub: {}", npub.substring(0, Math.min(20, npub.length())) + "...");
            LOG.info("Device storage: {}", deviceStoragePath);
            LOG.info("Relay ID: {}", relayId);
            LOG.info("Connected devices: {}", devices.size());
            LOG.info("══════════════════════════════════════");

            // Log to file
            LogManager logManager = GeogramRelay.getLogManager();
            if (logManager != null) {
                logManager.log(String.format("HELLO: %s from %s (npub: %s...)",
                    callsign, ctx.session.getRemoteAddress(),
                    pubkey.substring(0, Math.min(16, pubkey.length()))));
            }

            // Request collections from device
            requestCollections(ctx, callsign);

        } catch (Exception e) {
            LOG.error("Error handling hello message", e);
            sendHelloAck(ctx, false, "Error processing hello: " + e.getMessage());
        }
    }

    /**
     * Send hello acknowledgment
     */
    private void sendHelloAck(WsContext ctx, boolean success, String message) {
        sendHelloAck(ctx, success, message, null);
    }

    private void sendHelloAck(WsContext ctx, boolean success, String message, String relayId) {
        Map<String, Object> response = new HashMap<>();
        response.put("type", "hello_ack");
        response.put("success", success);
        response.put("message", message);
        if (relayId != null) {
            response.put("relay_id", relayId);
        }

        String json = new com.google.gson.Gson().toJson(response);
        ctx.send(json);

        LOG.info("Sent hello_ack: success={}, message={}", success, message);
    }

    /**
     * Handle REGISTER message
     */
    private void handleRegister(WsContext ctx, RelayMessage message) {
        String callsign = message.callsign;

        // Validate callsign
        if (callsign == null || !callsignPattern.matcher(callsign).matches()) {
            sendError(ctx, "Invalid callsign format");
            LOG.warn("Invalid callsign: {}", callsign);
            return;
        }

        // Check device limit
        if (devices.size() >= config.maxConnectedDevices) {
            sendError(ctx, "Server full - maximum devices reached");
            LOG.warn("Device limit reached, rejecting registration for: {}", callsign);
            return;
        }

        // Normalize callsign to uppercase
        callsign = callsign.toUpperCase();

        // Remove old connection if exists
        DeviceConnection oldDevice = devices.get(callsign);
        if (oldDevice != null) {
            LOG.info("Replacing existing connection for {}", callsign);
            contextToCallsign.remove(oldDevice.getContext());
            oldDevice.getContext().session.close();
        }

        // Create device storage directory
        String deviceStoragePath = createDeviceStorage(callsign);
        if (deviceStoragePath == null) {
            LOG.error("Failed to create device storage for {}", callsign);
            sendError(ctx, "Failed to create device storage");
            return;
        }

        // Register new connection (using REGISTER, so no npub available - use placeholder)
        DeviceConnection newDevice = new DeviceConnection(callsign, "unknown", ctx, deviceStoragePath);
        devices.put(callsign, newDevice);
        contextToCallsign.put(ctx, callsign);

        // Send confirmation
        RelayMessage response = RelayMessage.createRegister(callsign);
        ctx.send(response.toJson());

        LOG.info("Device registered: {}", callsign);

        // Log to file
        LogManager logManager = GeogramRelay.getLogManager();
        if (logManager != null) {
            logManager.log(String.format("DEVICE_CONNECT: %s from %s",
                callsign, ctx.session.getRemoteAddress()));
        }
    }

    /**
     * Handle HTTP_RESPONSE message
     */
    private void handleHttpResponse(WsContext ctx, RelayMessage message) {
        String requestId = message.requestId;
        if (requestId == null) {
            LOG.warn("HTTP_RESPONSE missing requestId");
            return;
        }

        PendingRequest pending = pendingRequests.remove(requestId);
        if (pending == null) {
            LOG.warn("No pending request found for requestId: {}", requestId);
            return;
        }

        // Update device activity
        String callsign = contextToCallsign.get(ctx);
        if (callsign != null) {
            DeviceConnection device = devices.get(callsign);
            if (device != null) {
                device.updateActivity();
            }
        }

        // Complete the request
        pending.complete(message);

        LOG.debug("HTTP response received for requestId: {}", requestId);
    }

    /**
     * Handle PING message
     */
    private void handlePing(WsContext ctx) {
        // Send PONG
        ctx.send(RelayMessage.createPong().toJson());

        // Update device activity
        String callsign = contextToCallsign.get(ctx);
        if (callsign != null) {
            DeviceConnection device = devices.get(callsign);
            if (device != null) {
                device.updateActivity();
                LOG.debug("PING from {}", callsign);
            }
        }
    }

    /**
     * Send error message
     */
    private void sendError(WsContext ctx, String error) {
        ctx.send(RelayMessage.createError(error).toJson());
    }

    /**
     * Forward HTTP request to device
     */
    public PendingRequest forwardHttpRequest(String callsign, String requestId,
            String method, String path, Map<String, String> headers, String body) {

        DeviceConnection device = devices.get(callsign.toUpperCase());
        if (device == null) {
            throw new IllegalStateException("Device not connected");
        }

        // Check pending request limit
        if (pendingRequests.size() >= config.maxPendingRequests) {
            throw new IllegalStateException("Too many pending requests");
        }

        // Convert headers to JSON
        String headersJson = new com.google.gson.Gson().toJson(headers);

        // Create HTTP_REQUEST message
        RelayMessage request = RelayMessage.createHttpRequest(
                requestId, method, path, headersJson, body != null ? body : "");

        // Create pending request
        PendingRequest pending = new PendingRequest(requestId, null);
        pendingRequests.put(requestId, pending);

        // Send to device
        device.sendMessage(request);

        LOG.info("Forwarded HTTP {} {} to device {}", method, path, callsign);

        return pending;
    }

    /**
     * Get device connection
     */
    public DeviceConnection getDevice(String callsign) {
        return devices.get(callsign.toUpperCase());
    }

    /**
     * Get all connected devices
     */
    public Collection<DeviceConnection> getDevices() {
        return new ArrayList<>(devices.values());
    }

    /**
     * Fail all pending requests for a device
     */
    private void failPendingRequestsForDevice(String callsign) {
        pendingRequests.values().removeIf(pending -> {
            pending.completeExceptionally(new Exception("Device disconnected"));
            return true;
        });
    }

    /**
     * Periodic cleanup of idle connections and timed-out requests
     */
    private void cleanup() {
        try {
            long now = System.currentTimeMillis();

            // Remove idle connections
            devices.values().removeIf(device -> {
                if (device.getIdleSeconds() > config.idleDeviceTimeout) {
                    LOG.info("Removing idle device: {} (idle for {}s)",
                            device.getCallsign(), device.getIdleSeconds());
                    contextToCallsign.remove(device.getContext());
                    device.getContext().session.close();
                    return true;
                }
                return false;
            });

            // Timeout pending requests
            pendingRequests.values().removeIf(pending -> {
                if (pending.isTimedOut(config.httpRequestTimeout)) {
                    LOG.warn("Request timeout: {}", pending.getRequestId());
                    pending.completeExceptionally(new Exception("Request timeout"));
                    return true;
                }
                return false;
            });

        } catch (Exception e) {
            LOG.error("Error during cleanup", e);
        }
    }

    /**
     * Create device storage directory structure
     * Creates: devices/{callsign}/collections/
     *
     * @param callsign Device callsign
     * @return Full path to device storage directory, or null on failure
     */
    private String createDeviceStorage(String callsign) {
        try {
            // Create base devices directory
            java.nio.file.Path basePath = java.nio.file.Paths.get(config.deviceStoragePath);
            if (!java.nio.file.Files.exists(basePath)) {
                java.nio.file.Files.createDirectories(basePath);
                LOG.info("Created base devices directory: {}", basePath.toAbsolutePath());
            }

            // Create device-specific directory
            java.nio.file.Path devicePath = basePath.resolve(callsign);
            if (!java.nio.file.Files.exists(devicePath)) {
                java.nio.file.Files.createDirectories(devicePath);
                LOG.info("Created device directory: {}", devicePath.toAbsolutePath());
            }

            // Create collections subdirectory
            java.nio.file.Path collectionsPath = devicePath.resolve("collections");
            if (!java.nio.file.Files.exists(collectionsPath)) {
                java.nio.file.Files.createDirectories(collectionsPath);
                LOG.info("Created collections directory: {}", collectionsPath.toAbsolutePath());
            }

            return devicePath.toAbsolutePath().toString();

        } catch (Exception e) {
            LOG.error("Failed to create device storage for callsign: {}", callsign, e);
            return null;
        }
    }

    /**
     * Request collections list from device
     */
    private void requestCollections(WsContext ctx, String callsign) {
        String requestId = "coll-" + System.currentTimeMillis();
        RelayMessage request = RelayMessage.createCollectionsRequest(requestId);

        ctx.send(request.toJson());
        LOG.info("Requested collections from device: {}", callsign);
    }

    /**
     * Handle COLLECTIONS_RESPONSE from device
     */
    private void handleCollectionsResponse(WsContext ctx, RelayMessage message) {
        String callsign = contextToCallsign.get(ctx);
        if (callsign == null) {
            LOG.warn("Received collections response from unregistered device");
            return;
        }

        if (message.collections == null || message.collections.length == 0) {
            LOG.info("Device {} has no collections", callsign);
            return;
        }

        LOG.info("Received {} collections from device {}", message.collections.length, callsign);

        // Request each collection's files (collection and tree-data)
        for (String collection : message.collections) {
            requestCollectionFile(ctx, callsign, collection, "collection");
            requestCollectionFile(ctx, callsign, collection, "tree-data");
        }
    }

    /**
     * Request a specific file from a collection
     */
    private void requestCollectionFile(WsContext ctx, String callsign, String collectionName, String fileName) {
        String requestId = "file-" + System.currentTimeMillis() + "-" + fileName;
        RelayMessage request = RelayMessage.createCollectionFileRequest(requestId, collectionName, fileName);

        ctx.send(request.toJson());
        LOG.debug("Requested {} file for collection {} from device {}", fileName, collectionName, callsign);
    }

    /**
     * Handle COLLECTION_FILE_RESPONSE from device
     */
    private void handleCollectionFileResponse(WsContext ctx, RelayMessage message) {
        String callsign = contextToCallsign.get(ctx);
        if (callsign == null) {
            LOG.warn("Received collection file response from unregistered device");
            return;
        }

        if (message.collectionName == null || message.fileName == null || message.fileContent == null) {
            LOG.warn("Invalid collection file response from device {}", callsign);
            return;
        }

        // Store the file
        storeCollectionFile(callsign, message.collectionName, message.fileName, message.fileContent);
    }

    /**
     * Store collection file to disk
     */
    private void storeCollectionFile(String callsign, String collectionName, String fileName, String content) {
        try {
            // Create directory structure: devices/{callsign}/collections/{collectionName}/
            java.nio.file.Path devicesBase = java.nio.file.Paths.get(config.deviceStoragePath);
            java.nio.file.Path callsignDir = devicesBase.resolve(callsign);
            java.nio.file.Path collectionsDir = callsignDir.resolve("collections");
            java.nio.file.Path collectionDir = collectionsDir.resolve(collectionName);

            if (!java.nio.file.Files.exists(collectionDir)) {
                java.nio.file.Files.createDirectories(collectionDir);
                LOG.info("Created collection directory: {}", collectionDir.toAbsolutePath());
            }

            // Write file
            java.nio.file.Path filePath = collectionDir.resolve(fileName);
            java.nio.file.Files.writeString(filePath, content);

            LOG.info("Stored {} for collection {} from device {} ({} bytes)",
                fileName, collectionName, callsign, content.length());

        } catch (Exception e) {
            LOG.error("Failed to store collection file: {}/{}/{}", callsign, collectionName, fileName, e);
        }
    }

    /**
     * Shutdown the server
     */
    public void shutdown() {
        scheduler.shutdown();
        devices.clear();
        pendingRequests.clear();
        contextToCallsign.clear();
        LOG.info("Relay server shut down");
    }
}
