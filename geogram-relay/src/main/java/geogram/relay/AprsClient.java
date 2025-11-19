/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * APRS-IS Client for announcing relay availability and discovering other relays
 *
 * Features:
 * - Sends periodic announcements with relay location, URL, and custom message
 * - Listens for announcements from other X3 relays (filter: p/X3)
 * - Maintains list of discovered relays
 * - Auto-reconnection on connection loss
 *
 * @author brito
 */
public class AprsClient {

    private static final Logger LOG = LoggerFactory.getLogger(AprsClient.class);

    // APRS filter to receive messages FROM X3* callsigns (relay announcements)
    private static final String APRS_FILTER = "p/X3";

    private final Config config;
    private final ScheduledExecutorService scheduler;
    private final AtomicBoolean running = new AtomicBoolean(false);
    private final AtomicBoolean shouldReconnect = new AtomicBoolean(true);

    // Connection state
    private Socket socket;
    private BufferedReader reader;
    private BufferedWriter writer;
    private Thread listenerThread;

    // Discovered relays (callsign -> DiscoveredRelay)
    private final Map<String, DiscoveredRelay> discoveredRelays = new ConcurrentHashMap<>();

    public AprsClient(Config config) {
        this.config = config;
        this.scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "APRS-Announcer");
            t.setDaemon(true);
            return t;
        });
    }

    /**
     * Start APRS client - announces relay and listens for other relays
     */
    public void start() {
        if (!config.enableAprs) {
            LOG.info("APRS announcements disabled in configuration");
            return;
        }

        if (running.getAndSet(true)) {
            LOG.warn("APRS client already running");
            return;
        }

        LOG.info("Starting APRS client for callsign: {}", config.aprsCallsign);
        LOG.info("Relay URL: {}", config.relayUrl != null ? config.relayUrl : "(not set)");
        LOG.info("APRS filter: {} (listening for X3* relay announcements)", APRS_FILTER);

        shouldReconnect.set(true);

        // Start listener thread for incoming APRS messages
        listenerThread = new Thread(this::connectionLoop, "APRS-Listener");
        listenerThread.setDaemon(true);
        listenerThread.start();

        // Schedule periodic announcements
        long intervalSeconds = config.aprsAnnouncementIntervalMinutes * 60;
        scheduler.scheduleAtFixedRate(
            this::sendAnnouncement,
            intervalSeconds, // Wait one interval before first announcement
            intervalSeconds,
            TimeUnit.SECONDS
        );

        LOG.info("APRS announcements scheduled every {} minutes ({} seconds)",
                 config.aprsAnnouncementIntervalMinutes, intervalSeconds);
    }

    /**
     * Stop APRS client
     */
    public void stop() {
        if (!running.getAndSet(false)) {
            return;
        }

        LOG.info("Stopping APRS client");

        shouldReconnect.set(false);

        // Stop scheduler
        scheduler.shutdown();
        try {
            scheduler.awaitTermination(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
            Thread.currentThread().interrupt();
        }

        // Stop listener thread
        if (listenerThread != null) {
            listenerThread.interrupt();
            try {
                listenerThread.join(5000);
            } catch (InterruptedException e) {
                // Ignore
            }
        }

        // Close connection
        disconnect();

        LOG.info("APRS client stopped");
    }

    /**
     * Connection loop - maintains connection and receives messages
     */
    private void connectionLoop() {
        while (shouldReconnect.get() && running.get()) {
            try {
                connect();

                // Send immediate announcement after connection
                sendAnnouncement();

                // Read and process incoming messages
                String line;
                while ((line = reader.readLine()) != null && running.get()) {
                    handleIncomingMessage(line);
                }

                LOG.warn("Connection closed by server");

            } catch (Exception e) {
                if (running.get()) {
                    LOG.error("Connection error: {}", e.getMessage());
                }
            } finally {
                disconnect();
            }

            // Wait before reconnecting
            if (shouldReconnect.get() && running.get()) {
                LOG.info("Reconnecting in 30 seconds...");
                try {
                    Thread.sleep(30000);
                } catch (InterruptedException e) {
                    break;
                }
            }
        }
    }

    /**
     * Connect to APRS-IS server
     */
    private void connect() throws Exception {
        LOG.info("Connecting to {}:{}...", config.aprsServer, config.aprsPort);

        socket = new Socket(config.aprsServer, config.aprsPort);
        reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream()));

        // Read server banner
        String banner = reader.readLine();
        LOG.info("Server: {}", banner);

        // Login with filter for X3* callsigns
        int passcode = calculatePasscode(config.aprsCallsign);
        String login = String.format("user %s pass %d vers Geogram-Relay 1.0 filter %s",
            config.aprsCallsign, passcode, APRS_FILTER);

        writer.write(login);
        writer.newLine();
        writer.flush();

        // Read login response
        String loginResp = reader.readLine();
        LOG.info("Login response: {}", loginResp);

        if (loginResp == null || !loginResp.contains("verified")) {
            throw new Exception("Login failed: " + loginResp);
        }

        LOG.info("✓ Connected to APRS-IS (listening for X3* relay announcements)");
    }

    /**
     * Disconnect from APRS-IS server
     */
    private void disconnect() {
        try {
            if (writer != null) {
                writer.close();
            }
            if (reader != null) {
                reader.close();
            }
            if (socket != null) {
                socket.close();
            }
        } catch (Exception e) {
            LOG.debug("Error during disconnect", e);
        }

        writer = null;
        reader = null;
        socket = null;
    }

    /**
     * Handle incoming APRS message
     */
    private void handleIncomingMessage(String message) {
        // Skip server messages (starting with #)
        if (message.startsWith("#")) {
            LOG.debug("Server message: {}", message);
            return;
        }

        // Parse APRS message to extract relay information
        // Format: X3XXXX>APRS,TCPIP*:!/####LLLLLLLL$MESSAGE URL
        try {
            if (message.contains(">") && message.contains(":")) {
                String callsign = message.substring(0, message.indexOf(">"));

                // Skip our own announcements
                if (callsign.equalsIgnoreCase(config.aprsCallsign)) {
                    return;
                }

                // Only process X3* callsigns (relays)
                if (!callsign.toUpperCase().startsWith("X3")) {
                    return;
                }

                // Extract message body (after ":")
                int colonIdx = message.indexOf(":");
                String body = message.substring(colonIdx + 1);

                // Check if it's a position report (starts with !/=@)
                if (body.startsWith("!")) {
                    parseRelayAnnouncement(callsign, body);
                }
            }
        } catch (Exception e) {
            LOG.warn("Error parsing APRS message: {} - {}", message, e.getMessage());
        }
    }

    /**
     * Parse relay announcement and extract coordinates + URL
     */
    private void parseRelayAnnouncement(String callsign, String body) {
        try {
            // Format: !/####LLLLLLLL$MESSAGE - URL
            // Extract compressed coordinates (8 chars after ####)
            if (body.length() < 15) {
                return;
            }

            // Skip the position indicator and symbol (!/####)
            String coords = body.substring(6, 14); // 8 chars: LLLLLLLL
            String lat4 = coords.substring(0, 4);
            String lon4 = coords.substring(4, 8);

            // Decode coordinates
            double latitude = AprsCompressed.decodeLat(lat4);
            double longitude = AprsCompressed.decodeLon(lon4);

            // Extract message part (after $)
            int dollarIdx = body.indexOf('$');
            if (dollarIdx == -1) {
                return;
            }

            String messagePart = body.substring(dollarIdx + 1);

            // Extract URL from message (look for " - " divisor followed by http:// or https://)
            String url = null;
            if (messagePart.contains(" - ")) {
                // Split by " - " divisor
                int divisorIdx = messagePart.indexOf(" - ");
                String afterDivisor = messagePart.substring(divisorIdx + 3); // Skip " - "

                // Check if what follows is a URL
                if (afterDivisor.startsWith("http://") || afterDivisor.startsWith("https://") ||
                    afterDivisor.startsWith("wss://") || afterDivisor.startsWith("ws://")) {
                    // URL ends at first space or end of string
                    int spaceIdx = afterDivisor.indexOf(' ');
                    url = spaceIdx != -1 ? afterDivisor.substring(0, spaceIdx) : afterDivisor;
                }
            }

            if (url != null) {
                // Add or update discovered relay
                DiscoveredRelay relay = discoveredRelays.get(callsign);
                if (relay == null) {
                    relay = new DiscoveredRelay(callsign, latitude, longitude, url);
                    discoveredRelays.put(callsign, relay);
                    LOG.info("═══════════════════════════════════════════════════════");
                    LOG.info("✓ DISCOVERED NEW RELAY VIA APRS");
                    LOG.info("═══════════════════════════════════════════════════════");
                    LOG.info("  Callsign: {}", callsign);
                    LOG.info("  URL:      {}", url);
                    LOG.info("  Location: {}, {}", String.format("%.4f", latitude), String.format("%.4f", longitude));
                    LOG.info("  Total discovered relays: {}", discoveredRelays.size());
                    LOG.info("═══════════════════════════════════════════════════════");

                    // Log to file
                    LogManager logManager = GeogramRelay.getLogManager();
                    if (logManager != null) {
                        logManager.log(String.format("RELAY_DISCOVERED: %s at %s (%.4f, %.4f)",
                            callsign, url, latitude, longitude));
                    }
                } else {
                    // Update last seen time
                    relay.updateLastSeen();
                    LOG.debug("Updated relay: {} (age: {}s)", callsign, relay.getAgeSeconds());
                }
            }

        } catch (Exception e) {
            LOG.warn("Error parsing relay announcement from {}: {}", callsign, e.getMessage());
        }
    }

    /**
     * Send relay announcement to APRS-IS
     */
    private void sendAnnouncement() {
        if (!running.get()) {
            return;
        }

        if (writer == null) {
            LOG.warn("Cannot send announcement - not connected to APRS-IS");
            return;
        }

        // Only announce if we have a public IP
        if (!isPublicIpAddress()) {
            LOG.warn("Skipping APRS announcement - relay does not have a public IP address");
            return;
        }

        try {
            String announcement = buildAnnouncement();

            writer.write(announcement);
            writer.newLine();
            writer.flush();

            LOG.info("APRS announcement sent: {}", announcement);

        } catch (Exception e) {
            LOG.error("Failed to send APRS announcement: {}", e.getMessage());
        }
    }

    /**
     * Build APRS announcement message with relay URL
     *
     * Format: CALLSIGN>APRS,TCPIP*:!/####LLLLLLLL$MESSAGE - URL
     */
    private String buildAnnouncement() {
        // Encode coordinates in APRS compressed format
        String compressedCoords = AprsCompressed.encodePairCompact(config.latitude, config.longitude);

        // Build message with URL
        String message = config.aprsMessage != null ? config.aprsMessage : "Geogram Relay";
        String url = config.relayUrl != null ? config.relayUrl : "";

        // Combine message and URL with " - " divisor
        String fullMessage = url.isEmpty() ? message : message + " - " + url;

        // Build standard APRS position beacon
        String position = String.format("!/####%s$%s", compressedCoords, fullMessage);

        return String.format("%s>APRS,TCPIP*:%s",
            config.aprsCallsign.toUpperCase(), position);
    }

    /**
     * Calculate APRS-IS passcode
     */
    private static int calculatePasscode(String callsign) {
        callsign = callsign.toUpperCase().split("-")[0];
        int hash = 0x73e2;
        for (int i = 0; i < callsign.length(); i++) {
            hash ^= callsign.charAt(i) << 8;
            if (++i < callsign.length()) {
                hash ^= callsign.charAt(i);
            }
        }
        return hash & 0x7FFF;
    }

    /**
     * Check if configured IP is public
     */
    private boolean isPublicIpAddress() {
        try {
            String ip = config.serverIp;
            if (ip == null || ip.equals("unknown")) {
                return false;
            }

            InetAddress addr = InetAddress.getByName(ip);
            return !addr.isSiteLocalAddress() &&
                   !addr.isLoopbackAddress() &&
                   !addr.isLinkLocalAddress() &&
                   !addr.isAnyLocalAddress();
        } catch (Exception e) {
            LOG.warn("Error checking IP address: {}", e.getMessage());
            return false;
        }
    }

    /**
     * Get list of discovered relays
     */
    public Collection<DiscoveredRelay> getDiscoveredRelays() {
        return new ArrayList<>(discoveredRelays.values());
    }

    /**
     * Get count of discovered relays
     */
    public int getDiscoveredRelayCount() {
        return discoveredRelays.size();
    }
}
