/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import io.javalin.websocket.WsContext;

/**
 * Represents a connected device
 *
 * @author brito
 */
public class DeviceConnection {

    private final String callsign;
    private final String npub;
    private final WsContext context;
    private final long connectedAt;
    private long lastActivity;
    private final String deviceStoragePath;

    public DeviceConnection(String callsign, String npub, WsContext context, String deviceStoragePath) {
        this.callsign = callsign;
        this.npub = npub;
        this.context = context;
        this.connectedAt = System.currentTimeMillis();
        this.lastActivity = System.currentTimeMillis();
        this.deviceStoragePath = deviceStoragePath;
    }

    public String getCallsign() {
        return callsign;
    }

    public String getNpub() {
        return npub;
    }

    public WsContext getContext() {
        return context;
    }

    public String getDeviceStoragePath() {
        return deviceStoragePath;
    }

    public long getConnectedAt() {
        return connectedAt;
    }

    public long getLastActivity() {
        return lastActivity;
    }

    public void updateActivity() {
        this.lastActivity = System.currentTimeMillis();
    }

    public long getUptimeSeconds() {
        return (System.currentTimeMillis() - connectedAt) / 1000;
    }

    public long getIdleSeconds() {
        return (System.currentTimeMillis() - lastActivity) / 1000;
    }

    public void sendMessage(RelayMessage message) {
        context.send(message.toJson());
        updateActivity();
    }

    @Override
    public String toString() {
        return "DeviceConnection{callsign=" + callsign +
               ", uptime=" + getUptimeSeconds() + "s" +
               ", idle=" + getIdleSeconds() + "s}";
    }
}
