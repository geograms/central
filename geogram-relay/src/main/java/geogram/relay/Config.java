/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 * Configuration management for Geogram Relay Server
 * Loads settings from config.json in the working directory
 *
 * @author brito
 */
public class Config {

    private static final Logger LOG = LoggerFactory.getLogger(Config.class);
    private static final String CONFIG_FILE = "config.json";
    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    // Server settings
    public int port = 8080;  // Default for local testing (use 80 for production)
    public String host = "0.0.0.0";
    public boolean enableLogging = true;

    // SSL/TLS settings
    public boolean enableSsl = false;
    public String keystorePath = "keystore.jks";
    public String keystorePassword = "changeit";
    public String keyPassword = null;  // If null, uses keystorePassword

    // Timeout settings (seconds)
    public long httpRequestTimeout = 30;
    public long idleDeviceTimeout = 600;      // 10 minutes (devices send PING every 60s)
    public long cleanupInterval = 300;         // 5 minutes

    // Connection limits
    public int maxConnectedDevices = 1000;
    public int maxPendingRequests = 10000;

    // Callsign validation
    public String callsignPattern = "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$";

    // CORS settings
    public boolean enableCors = false;
    public String corsAllowedOrigins = "*";

    // Rate limiting
    public boolean enableRateLimiting = false;
    public int maxRequestsPerMinute = 60;

    // APRS-IS Settings
    public boolean enableAprs = true;
    public String aprsCallsign = "";
    public String aprsServer = "rotate.aprs2.net";
    public int aprsPort = 14580;
    public long aprsAnnouncementIntervalMinutes = 5;  // Interval in minutes (default: 5 minutes)
    public String aprsMessage = "Geogram Relay";  // Custom message for APRS announcements (max ~200 chars)
    public String relayUrl = "";  // Public URL/IP for this relay (e.g., "http://relay.example.com:8080" or "http://192.168.1.100:8080")

    // Geolocation
    public boolean autoDetectLocation = true;
    public String serverIp = "unknown";
    public double latitude = 0.0;
    public double longitude = 0.0;
    public String city = "Unknown";
    public String region = "Unknown";
    public String country = "Unknown";
    public String countryCode = "XX";
    public String timezone = "UTC";
    public String isp = "Unknown";

    // Server description
    public String serverDescription = "Geogram relay server for amateur radio operations";

    // Device storage
    public String deviceStoragePath = "./devices";

    /**
     * Load configuration from config.json file
     */
    public static Config load() {
        File configFile = new File(CONFIG_FILE);

        Config config;
        boolean isNewConfig = !configFile.exists();

        if (configFile.exists()) {
            try (FileReader reader = new FileReader(configFile)) {
                config = GSON.fromJson(reader, Config.class);
                LOG.info("Configuration loaded from {}", CONFIG_FILE);
            } catch (IOException e) {
                LOG.error("Failed to load configuration from {}: {}", CONFIG_FILE, e.getMessage());
                LOG.info("Using default configuration");
                config = new Config();
                isNewConfig = true;
            }
        } else {
            LOG.info("Configuration file {} not found, creating default", CONFIG_FILE);
            config = new Config();
        }

        boolean needsSave = false;

        // Auto-generate APRS callsign if not set
        if (config.aprsCallsign == null || config.aprsCallsign.isEmpty()) {
            config.aprsCallsign = CallsignGenerator.generateCallsign();
            LOG.info("Generated relay callsign: {}", config.aprsCallsign);
            needsSave = true;
        }

        // Auto-detect location if enabled and not already set
        if (config.autoDetectLocation && (config.latitude == 0.0 && config.longitude == 0.0)) {
            LOG.info("Auto-detecting server location...");
            GeoLocation.Location location = GeoLocation.detectLocation();
            config.updateLocation(location);
            needsSave = true;
        }

        // Auto-generate relay URL if not set (use public IP + port)
        if (config.relayUrl == null || config.relayUrl.isEmpty()) {
            if (config.serverIp != null && !config.serverIp.equals("unknown")) {
                String protocol = config.enableSsl ? "https" : "http";
                config.relayUrl = String.format("%s://%s:%d", protocol, config.serverIp, config.port);
                LOG.info("Generated relay URL: {}", config.relayUrl);
                needsSave = true;
            }
        }

        // Save if new config or if changes were made
        if (isNewConfig || needsSave) {
            config.save();
        }

        return config;
    }

    /**
     * Update location fields from GeoLocation
     */
    public void updateLocation(GeoLocation.Location location) {
        this.serverIp = location.ip;
        this.latitude = location.latitude;
        this.longitude = location.longitude;
        this.city = location.city;
        this.region = location.region;
        this.country = location.country;
        this.countryCode = location.countryCode;
        this.timezone = location.timezone;
        this.isp = location.isp;
    }

    /**
     * Save current configuration to config.json file
     */
    public void save() {
        try (FileWriter writer = new FileWriter(CONFIG_FILE)) {
            GSON.toJson(this, writer);
            LOG.info("Configuration saved to {}", CONFIG_FILE);
        } catch (IOException e) {
            LOG.error("Failed to save configuration to {}: {}", CONFIG_FILE, e.getMessage());
        }
    }

    /**
     * Validate configuration values
     */
    public boolean validate() {
        if (port < 1 || port > 65535) {
            LOG.error("Invalid port: {} (must be 1-65535)", port);
            return false;
        }

        if (httpRequestTimeout < 1) {
            LOG.error("Invalid httpRequestTimeout: {} (must be >= 1)", httpRequestTimeout);
            return false;
        }

        if (idleDeviceTimeout < 1) {
            LOG.error("Invalid idleDeviceTimeout: {} (must be >= 1)", idleDeviceTimeout);
            return false;
        }

        if (cleanupInterval < 1) {
            LOG.error("Invalid cleanupInterval: {} (must be >= 1)", cleanupInterval);
            return false;
        }

        if (maxConnectedDevices < 1) {
            LOG.error("Invalid maxConnectedDevices: {} (must be >= 1)", maxConnectedDevices);
            return false;
        }

        if (maxPendingRequests < 1) {
            LOG.error("Invalid maxPendingRequests: {} (must be >= 1)", maxPendingRequests);
            return false;
        }

        if (enableSsl) {
            File keystoreFile = new File(keystorePath);
            if (!keystoreFile.exists()) {
                LOG.error("SSL enabled but keystore file not found: {}", keystorePath);
                return false;
            }
            if (keystorePassword == null || keystorePassword.isEmpty()) {
                LOG.error("SSL enabled but keystorePassword not set");
                return false;
            }
        }

        if (enableAprs) {
            // Callsign should be auto-generated by load(), but verify it's valid
            if (aprsCallsign == null || aprsCallsign.isEmpty()) {
                LOG.error("APRS enabled but aprsCallsign is empty (this should not happen)");
                return false;
            }
            if (!CallsignGenerator.isValidRelayCallsign(aprsCallsign)) {
                LOG.warn("APRS callsign '{}' is not in expected X3XXXX format", aprsCallsign);
                // Continue anyway - user might have custom callsign
            }
            if (aprsServer == null || aprsServer.isEmpty()) {
                LOG.error("APRS enabled but aprsServer not set");
                return false;
            }
            if (aprsPort < 1 || aprsPort > 65535) {
                LOG.error("Invalid aprsPort: {} (must be 1-65535)", aprsPort);
                return false;
            }
            if (aprsAnnouncementIntervalMinutes < 1) {
                LOG.error("Invalid aprsAnnouncementIntervalMinutes: {} (must be >= 1 minute)", aprsAnnouncementIntervalMinutes);
                return false;
            }

            // Validate APRS message length
            // APRS total message limit is ~256 chars
            // Format: CALLSIGN>APRS,TCPIP*:!/####LLLLLLLL$MESSAGE - URL
            // Overhead: ~34 chars (6 callsign + 13 header + 6 position + 8 coords + 1 delimiter)
            // Safe maximum for message: 200 chars
            if (aprsMessage == null) {
                aprsMessage = "Geogram Relay";
            }

            // Calculate combined length: message + " - " + URL
            String url = relayUrl != null ? relayUrl : "";
            String combinedMessage = url.isEmpty() ? aprsMessage : aprsMessage + " - " + url;

            if (combinedMessage.length() > 200) {
                LOG.error("APRS message + URL too long: {} characters (maximum: 200)", combinedMessage.length());
                LOG.error("Message: {}", aprsMessage);
                LOG.error("URL: {}", url);
                LOG.error("Combined: {}", combinedMessage);
                LOG.error("APRS packets are limited to ~256 characters total.");
                LOG.error("Please shorten the aprsMessage or relayUrl in config.json");
                return false;
            }
        }

        return true;
    }

    @Override
    public String toString() {
        return "Config{" +
                "port=" + port +
                ", host='" + host + '\'' +
                ", enableSsl=" + enableSsl +
                ", httpRequestTimeout=" + httpRequestTimeout +
                ", idleDeviceTimeout=" + idleDeviceTimeout +
                ", cleanupInterval=" + cleanupInterval +
                ", maxConnectedDevices=" + maxConnectedDevices +
                ", maxPendingRequests=" + maxPendingRequests +
                ", location=" + city + ", " + country +
                " (lat=" + String.format("%.4f", latitude) +
                ", lon=" + String.format("%.4f", longitude) + ")" +
                '}';
    }
}
