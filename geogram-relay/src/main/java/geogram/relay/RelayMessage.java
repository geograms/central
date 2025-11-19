/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

/**
 * Relay protocol message format
 *
 * @author brito
 */
public class RelayMessage {

    private static final Gson GSON = new GsonBuilder().create();

    // Message types
    public static final String TYPE_REGISTER = "REGISTER";
    public static final String TYPE_HTTP_REQUEST = "HTTP_REQUEST";
    public static final String TYPE_HTTP_RESPONSE = "HTTP_RESPONSE";
    public static final String TYPE_PING = "PING";
    public static final String TYPE_PONG = "PONG";
    public static final String TYPE_ERROR = "ERROR";

    // Common fields
    public String type;
    public String requestId;
    public String callsign;

    // HTTP_REQUEST fields
    public String method;
    public String path;
    public String headers;
    public String body;

    // HTTP_RESPONSE fields
    public Integer statusCode;
    public String responseHeaders;
    public String responseBody;

    // ERROR fields
    public String error;

    // Constructors
    public RelayMessage() {}

    public RelayMessage(String type) {
        this.type = type;
    }

    // Factory methods
    public static RelayMessage createRegister(String callsign) {
        RelayMessage msg = new RelayMessage(TYPE_REGISTER);
        msg.callsign = callsign;
        return msg;
    }

    public static RelayMessage createHttpRequest(String requestId, String method,
            String path, String headers, String body) {
        RelayMessage msg = new RelayMessage(TYPE_HTTP_REQUEST);
        msg.requestId = requestId;
        msg.method = method;
        msg.path = path;
        msg.headers = headers;
        msg.body = body;
        return msg;
    }

    public static RelayMessage createHttpResponse(String requestId, int statusCode,
            String responseHeaders, String responseBody) {
        RelayMessage msg = new RelayMessage(TYPE_HTTP_RESPONSE);
        msg.requestId = requestId;
        msg.statusCode = statusCode;
        msg.responseHeaders = responseHeaders;
        msg.responseBody = responseBody;
        return msg;
    }

    public static RelayMessage createPing() {
        return new RelayMessage(TYPE_PING);
    }

    public static RelayMessage createPong() {
        return new RelayMessage(TYPE_PONG);
    }

    public static RelayMessage createError(String error) {
        RelayMessage msg = new RelayMessage(TYPE_ERROR);
        msg.error = error;
        return msg;
    }

    // JSON serialization
    public String toJson() {
        return GSON.toJson(this);
    }

    public static RelayMessage fromJson(String json) {
        return GSON.fromJson(json, RelayMessage.class);
    }

    @Override
    public String toString() {
        return "RelayMessage{type=" + type + ", requestId=" + requestId +
               ", callsign=" + callsign + "}";
    }
}
