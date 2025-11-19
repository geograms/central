/*
 * Copyright (c) geogram
 * License: Apache-2.0
 */
package geogram.relay;

import io.javalin.http.Context;
import java.util.concurrent.CompletableFuture;

/**
 * Represents a pending HTTP request waiting for device response
 *
 * @author brito
 */
public class PendingRequest {

    private final String requestId;
    private final Context httpContext;
    private final long timestamp;
    private final CompletableFuture<RelayMessage> responseFuture;

    public PendingRequest(String requestId, Context httpContext) {
        this.requestId = requestId;
        this.httpContext = httpContext;
        this.timestamp = System.currentTimeMillis();
        this.responseFuture = new CompletableFuture<>();
    }

    public String getRequestId() {
        return requestId;
    }

    public Context getHttpContext() {
        return httpContext;
    }

    public long getTimestamp() {
        return timestamp;
    }

    public CompletableFuture<RelayMessage> getResponseFuture() {
        return responseFuture;
    }

    public long getElapsedSeconds() {
        return (System.currentTimeMillis() - timestamp) / 1000;
    }

    public boolean isTimedOut(long timeoutSeconds) {
        return getElapsedSeconds() > timeoutSeconds;
    }

    public void complete(RelayMessage response) {
        responseFuture.complete(response);
    }

    public void completeExceptionally(Throwable throwable) {
        responseFuture.completeExceptionally(throwable);
    }

    @Override
    public String toString() {
        return "PendingRequest{id=" + requestId +
               ", elapsed=" + getElapsedSeconds() + "s}";
    }
}
