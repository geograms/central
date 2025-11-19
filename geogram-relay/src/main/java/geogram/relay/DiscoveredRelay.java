/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

/**
 * Represents a relay discovered via APRS-IS
 *
 * @author brito
 */
public class DiscoveredRelay {

    private final String callsign;
    private final double latitude;
    private final double longitude;
    private final String url;
    private final long discoveredAt;
    private long lastSeenAt;

    public DiscoveredRelay(String callsign, double latitude, double longitude, String url) {
        this.callsign = callsign;
        this.latitude = latitude;
        this.longitude = longitude;
        this.url = url;
        this.discoveredAt = System.currentTimeMillis();
        this.lastSeenAt = System.currentTimeMillis();
    }

    public void updateLastSeen() {
        this.lastSeenAt = System.currentTimeMillis();
    }

    public String getCallsign() {
        return callsign;
    }

    public double getLatitude() {
        return latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public String getUrl() {
        return url;
    }

    public long getDiscoveredAt() {
        return discoveredAt;
    }

    public long getLastSeenAt() {
        return lastSeenAt;
    }

    public long getAgeSeconds() {
        return (System.currentTimeMillis() - lastSeenAt) / 1000;
    }

    @Override
    public String toString() {
        return String.format("DiscoveredRelay{callsign='%s', url='%s', lat=%.4f, lon=%.4f, age=%ds}",
            callsign, url, latitude, longitude, getAgeSeconds());
    }
}
