/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.URL;

/**
 * Automatic geolocation detection using IP address
 * Uses free ip-api.com service (no API key required)
 *
 * @author brito
 */
public class GeoLocation {

    private static final Logger LOG = LoggerFactory.getLogger(GeoLocation.class);
    private static final Gson GSON = new Gson();

    // Free IP geolocation service (15 requests/minute limit)
    private static final String IP_API_URL = "http://ip-api.com/json/";
    private static final int TIMEOUT_MS = 5000;

    public static class Location {
        public String ip;
        public double latitude;
        public double longitude;
        public String city;
        public String region;
        public String country;
        public String countryCode;
        public String timezone;
        public String isp;

        @Override
        public String toString() {
            return String.format("Location{lat=%.4f, lon=%.4f, city=%s, country=%s, ip=%s}",
                    latitude, longitude, city, country, ip);
        }
    }

    /**
     * Detect server location based on public IP address
     */
    public static Location detectLocation() {
        try {
            // Get public IP first
            String publicIp = getPublicIp();
            if (publicIp == null) {
                LOG.warn("Could not determine public IP address");
                return createDefaultLocation();
            }

            LOG.info("Detected public IP: {}", publicIp);

            // Get geolocation for the IP
            return getLocationForIp(publicIp);

        } catch (Exception e) {
            LOG.error("Failed to detect location: {}", e.getMessage());
            return createDefaultLocation();
        }
    }

    /**
     * Get public IP address using ipify.org
     */
    private static String getPublicIp() {
        try {
            URL url = new URL("https://api.ipify.org?format=text");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(TIMEOUT_MS);
            conn.setReadTimeout(TIMEOUT_MS);

            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String ip = reader.readLine();
            reader.close();

            return ip;
        } catch (Exception e) {
            LOG.warn("Failed to get public IP: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Get geolocation data for IP address using ip-api.com
     */
    private static Location getLocationForIp(String ip) {
        try {
            URL url = new URL(IP_API_URL + ip);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(TIMEOUT_MS);
            conn.setReadTimeout(TIMEOUT_MS);
            conn.setRequestProperty("Accept", "application/json");

            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            StringBuilder response = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                response.append(line);
            }
            reader.close();

            // Parse JSON response
            JsonObject json = GSON.fromJson(response.toString(), JsonObject.class);

            if (json.has("status") && json.get("status").getAsString().equals("success")) {
                Location location = new Location();
                location.ip = ip;
                location.latitude = json.has("lat") ? json.get("lat").getAsDouble() : 0.0;
                location.longitude = json.has("lon") ? json.get("lon").getAsDouble() : 0.0;
                location.city = json.has("city") ? json.get("city").getAsString() : "Unknown";
                location.region = json.has("regionName") ? json.get("regionName").getAsString() : "Unknown";
                location.country = json.has("country") ? json.get("country").getAsString() : "Unknown";
                location.countryCode = json.has("countryCode") ? json.get("countryCode").getAsString() : "XX";
                location.timezone = json.has("timezone") ? json.get("timezone").getAsString() : "UTC";
                location.isp = json.has("isp") ? json.get("isp").getAsString() : "Unknown";

                LOG.info("Location detected: {}", location);
                return location;
            } else {
                String message = json.has("message") ? json.get("message").getAsString() : "Unknown error";
                LOG.warn("IP API returned error: {}", message);
                return createDefaultLocation();
            }

        } catch (Exception e) {
            LOG.error("Failed to get location for IP {}: {}", ip, e.getMessage());
            return createDefaultLocation();
        }
    }

    /**
     * Create default location (0,0) when detection fails
     */
    private static Location createDefaultLocation() {
        Location location = new Location();
        location.ip = "unknown";
        location.latitude = 0.0;
        location.longitude = 0.0;
        location.city = "Unknown";
        location.region = "Unknown";
        location.country = "Unknown";
        location.countryCode = "XX";
        location.timezone = "UTC";
        location.isp = "Unknown";
        return location;
    }

    /**
     * Check if we're running on localhost
     */
    public static boolean isLocalhost() {
        try {
            InetAddress localhost = InetAddress.getLocalHost();
            String hostAddress = localhost.getHostAddress();
            return hostAddress.equals("127.0.0.1") || hostAddress.equals("0:0:0:0:0:0:0:1");
        } catch (Exception e) {
            return false;
        }
    }
}
