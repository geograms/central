# Geogram Relay API Documentation

This document describes the HTTP and WebSocket APIs provided by the Geogram Relay Server.

## Table of Contents

- [Overview](#overview)
- [HTTP Endpoints](#http-endpoints)
  - [Status & Information](#status--information)
  - [Device Proxy](#device-proxy)
  - [Collections & Search](#collections--search)
  - [Chat API](#chat-api)
  - [CLI API](#cli-api)
  - [SSL/ACME](#sslacme)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection](#connection)
  - [Device Messages](#device-messages)
  - [Relay-to-Relay Messages](#relay-to-relay-messages)
  - [Chat Messages](#chat-messages)
- [Admin Dashboard API](#admin-dashboard-api)
- [Error Handling](#error-handling)

---

## Overview

The Geogram Relay Server provides two main interfaces:

1. **Main Server** (default port 8080): HTTP and WebSocket endpoints for devices, clients, and relay-to-relay communication
2. **Admin Dashboard** (default port 8081): Web interface and API for relay administration (requires authentication)

Base URLs:
- Main Server: `http://relay-host:8080`
- WebSocket: `ws://relay-host:8080/`
- Admin Dashboard: `http://relay-host:8081`

---

## HTTP Endpoints

### Status & Information

#### GET /
Returns the relay home page (HTML interface).

**Response:** HTML page with relay information and connected devices.

---

#### GET /status
Legacy status endpoint. Returns relay status information.

**Response:**
```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "status": "online",
  "started_at": "2024-01-15T10:30:00Z",
  "uptime_hours": 24,
  "port": 8080,
  "description": "Geogram relay server for amateur radio operations",
  "connected_devices": 5,
  "max_devices": 1000,
  "devices": [
    {
      "callsign": "X3ABC123",
      "uptime_seconds": 3600,
      "idle_seconds": 60,
      "connected_at": "2024-01-15T11:30:00Z"
    }
  ],
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "city": "New York",
    "region": "NY",
    "country": "United States",
    "country_code": "US",
    "timezone": "America/New_York",
    "ip": "192.168.1.1",
    "isp": "Example ISP"
  }
}
```

---

#### GET /api/status
Detailed relay status (same format as `/status`).

---

#### GET /relay/status
List all connected devices and relays.

**Response:**
```json
{
  "connected_devices": 5,
  "connected_relays": 2,
  "devices": [
    {
      "callsign": "X3ABC123",
      "uptime_seconds": 3600,
      "idle_seconds": 60,
      "connected_at": "2024-01-15T11:30:00Z"
    }
  ]
}
```

---

#### GET /device/{callsign}
Get information about a specific connected device.

**Path Parameters:**
- `callsign` - Device callsign (case-insensitive)

**Response (200 - Device connected):**
```json
{
  "callsign": "X3ABC123",
  "connected": true,
  "uptime": 3600,
  "idleTime": 60
}
```

**Response (404 - Device not connected):**
```json
{
  "callsign": "X3ABC123",
  "connected": false,
  "error": "Device not connected"
}
```

---

### Device Proxy

#### ANY /device/{callsign}/*
Proxy HTTP requests to a connected device. Supports all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS).

**Path Parameters:**
- `callsign` - Device callsign
- `*` - Path to forward to the device

**Example:**
```
GET /device/X3ABC123/api/collections
```

The relay forwards the request to the device over WebSocket and returns the device's response.

**Response:** Varies based on the device's response.

---

#### GET /{callsign}
Serve the `www` collection index from a device.

**Path Parameters:**
- `callsign` - Device callsign

**Response:** HTML content from the device's `www` collection.

---

#### GET /{callsign}/*
Serve files from a device's `www` collection.

**Path Parameters:**
- `callsign` - Device callsign
- `*` - File path within the `www` collection

**Example:**
```
GET /X3ABC123/images/logo.png
```

---

### Collections & Search

#### GET /search
Search across all connected devices' collections.

**Query Parameters:**
- `q` (required) - Search query string
- `limit` (optional) - Maximum results (1-500, default: 50)

**Response:**
```json
{
  "query": "example search",
  "total_results": 10,
  "limit": 50,
  "results": [
    {
      "callsign": "X3ABC123",
      "collection": "documents",
      "file": "example.txt",
      "score": 0.95
    }
  ]
}
```

**Error Response (400):**
```json
{
  "error": "Missing query parameter 'q'"
}
```

---

### Chat API

#### GET /api/chat/rooms
List all available chat rooms.

**Response:**
```json
{
  "relay": "X3RELAY1",
  "rooms": [
    {
      "id": "general",
      "name": "General",
      "description": "General discussion",
      "message_count": 150
    }
  ],
  "count": 1
}
```

---

#### GET /api/chat/rooms/{roomId}/messages
Get messages from a chat room.

**Path Parameters:**
- `roomId` - Chat room ID

**Query Parameters:**
- `limit` (optional) - Maximum messages (1-200, default: 50)

**Response:**
```json
{
  "room_id": "general",
  "room_name": "General",
  "messages": [
    {
      "timestamp": "2024-01-15T12:00:00Z",
      "callsign": "X1USER01",
      "content": "Hello, world!"
    }
  ],
  "count": 1
}
```

**Error Response (404):**
```json
{
  "error": "Room not found"
}
```

---

#### POST /api/chat/rooms/{roomId}/messages
Post a message to a chat room. Supports both legacy and NOSTR-signed messages.

**Path Parameters:**
- `roomId` - Chat room ID

**Request Body (Legacy):**
```json
{
  "callsign": "X1USER01",
  "content": "Hello, world!"
}
```

**Request Body (NOSTR):**
```json
{
  "callsign": "X1USER01",
  "content": "Hello, world!",
  "npub": "npub1...",
  "pubkey": "hex_pubkey",
  "event_id": "hex_event_id",
  "signature": "hex_signature",
  "created_at": 1705320000
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Message posted"
}
```

**Error Responses:**
- `400` - Missing callsign, content, or invalid signature
- `404` - Room not found
- `503` - Chat service not available

---

#### POST /api/relay/send
Send a message from the relay as a NOSTR-signed event.

**Request Body:**
```json
{
  "room": "general",
  "content": "Announcement from relay",
  "callsign": "X3RELAY1"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Message sent as NOSTR event",
  "room": "general",
  "callsign": "X3RELAY1",
  "content": "Announcement from relay",
  "devices_notified": 5,
  "connected_devices": 10,
  "nostr_event": {
    "id": "event_id_hex",
    "pubkey": "pubkey_hex",
    "created_at": 1705320000,
    "kind": 1,
    "tags": [
      ["t", "chat"],
      ["room", "general"],
      ["callsign", "X3RELAY1"]
    ],
    "content": "Announcement from relay",
    "sig": "signature_hex"
  }
}
```

---

### CLI API

#### POST /api/cli
Execute a CLI command remotely.

**Request Body:**
```json
{
  "command": "status"
}
```

**Response:**
```json
{
  "command": "status",
  "output": "Relay Status:\n  Connected devices: 5\n  ..."
}
```

**Error Response (400):**
```json
{
  "error": "Missing 'command' field"
}
```

---

### SSL/ACME

#### GET /.well-known/acme-challenge/{token}
ACME HTTP-01 challenge endpoint for Let's Encrypt SSL certificate verification.

**Path Parameters:**
- `token` - ACME challenge token

**Response:** Plain text challenge response or 404 if not found.

---

### Map Tiles

#### GET /tiles/{callsign}/{z}/{x}/{y}.png
Serve map tiles (if tile server is enabled).

**Path Parameters:**
- `callsign` - Device callsign
- `z` - Zoom level
- `x` - Tile X coordinate
- `y` - Tile Y coordinate

**Response:** PNG image tile.

---

## WebSocket Protocol

### Connection

Connect to the WebSocket endpoint at `ws://relay-host:8080/`.

All messages are JSON-encoded. The basic message structure:

```json
{
  "type": "MESSAGE_TYPE",
  "requestId": "optional_request_id",
  "callsign": "device_callsign",
  ...additional fields
}
```

---

### Device Messages

#### REGISTER
Register a device with the relay.

**Client → Relay:**
```json
{
  "type": "REGISTER",
  "callsign": "X3ABC123"
}
```

---

#### HTTP_REQUEST / HTTP_RESPONSE
Proxy HTTP requests through the relay to devices.

**Relay → Device (Request):**
```json
{
  "type": "HTTP_REQUEST",
  "requestId": "uuid",
  "method": "GET",
  "path": "/api/collections",
  "headers": "Accept: application/json\r\n...",
  "body": ""
}
```

**Device → Relay (Response):**
```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "uuid",
  "statusCode": 200,
  "responseHeaders": "Content-Type: application/json\r\n...",
  "responseBody": "{...}",
  "isBase64": false
}
```

---

#### PING / PONG
Keep-alive heartbeat messages.

**Client → Relay:**
```json
{
  "type": "PING"
}
```

**Relay → Client:**
```json
{
  "type": "PONG"
}
```

---

#### ERROR
Error notification.

**Relay → Client:**
```json
{
  "type": "ERROR",
  "error": "Error description"
}
```

---

#### COLLECTIONS_REQUEST / COLLECTIONS_RESPONSE
Request list of collections from a device.

**Relay → Device:**
```json
{
  "type": "COLLECTIONS_REQUEST",
  "requestId": "uuid"
}
```

**Device → Relay:**
```json
{
  "type": "COLLECTIONS_RESPONSE",
  "requestId": "uuid",
  "collections": ["www", "documents", "images"]
}
```

---

#### COLLECTION_FILE_REQUEST / COLLECTION_FILE_RESPONSE
Request a specific file from a collection.

**Relay → Device:**
```json
{
  "type": "COLLECTION_FILE_REQUEST",
  "requestId": "uuid",
  "collectionName": "documents",
  "fileName": "collection"
}
```

**Device → Relay:**
```json
{
  "type": "COLLECTION_FILE_RESPONSE",
  "requestId": "uuid",
  "fileContent": "..."
}
```

---

### Relay-to-Relay Messages

These messages are used for communication between root and node relays.

#### RELAY_HELLO
Node relay introduces itself to root relay.

**Node → Root:**
```json
{
  "type": "RELAY_HELLO",
  "relayCallsign": "X3NODE01",
  "relayNpub": "npub1...",
  "operatorCallsign": "X1OPERATOR",
  "relayType": "node",
  "networkId": "mynetwork",
  "relayPort": 8080
}
```

---

#### RELAY_HELLO_ACK
Root relay acknowledges node relay connection.

**Root → Node:**
```json
{
  "type": "RELAY_HELLO_ACK",
  "accepted": true,
  "assignedId": "node-X3NODE01-1705320000",
  "rejectReason": null
}
```

Or if rejected:
```json
{
  "type": "RELAY_HELLO_ACK",
  "accepted": false,
  "assignedId": null,
  "rejectReason": "Network ID mismatch"
}
```

---

#### RELAY_STATUS
Periodic status update between relays.

```json
{
  "type": "RELAY_STATUS",
  "relayCallsign": "X3NODE01",
  ...status fields
}
```

---

### Chat Messages

#### CHAT_ROOMS_REQUEST / CHAT_ROOMS_RESPONSE
Request list of available chat rooms.

**Client → Relay:**
```json
{
  "type": "CHAT_ROOMS_REQUEST",
  "requestId": "uuid"
}
```

**Relay → Client:**
```json
{
  "type": "CHAT_ROOMS_RESPONSE",
  "requestId": "uuid",
  "roomIds": ["general", "emergency"],
  "roomNames": ["General", "Emergency"],
  "roomDescriptions": ["General discussion", "Emergency communications"]
}
```

---

#### CHAT_MESSAGE
Send or receive a chat message.

```json
{
  "type": "CHAT_MESSAGE",
  "roomId": "general",
  "messageId": "uuid",
  "senderCallsign": "X1USER01",
  "senderNpub": "npub1...",
  "content": "Hello, world!",
  "timestamp": 1705320000000,
  "originRelay": "X3RELAY1"
}
```

---

#### CHAT_MESSAGE_ACK
Acknowledge receipt of a chat message.

```json
{
  "type": "CHAT_MESSAGE_ACK",
  "messageId": "uuid",
  "accepted": true
}
```

---

#### CHAT_SYNC
Sync messages between relays.

```json
{
  "type": "CHAT_SYNC",
  "roomId": "general",
  "messageIds": ["id1", "id2"],
  "messageSenders": ["X1USER01", "X1USER02"],
  "messageContents": ["Hello", "Hi there"],
  "messageTimestamps": [1705320000000, 1705320060000],
  "originRelay": "X3NODE01"
}
```

---

#### CHAT_HISTORY_REQUEST / CHAT_HISTORY_RESPONSE
Request message history for a room.

**Client → Relay:**
```json
{
  "type": "CHAT_HISTORY_REQUEST",
  "requestId": "uuid",
  "roomId": "general",
  "messageCount": 50
}
```

**Relay → Client:**
```json
{
  "type": "CHAT_HISTORY_RESPONSE",
  "requestId": "uuid",
  "roomId": "general",
  "messageIds": ["id1", "id2"],
  "messageSenders": ["X1USER01", "X1USER02"],
  "messageContents": ["Hello", "Hi there"],
  "messageTimestamps": [1705320000000, 1705320060000]
}
```

---

## Admin Dashboard API

The Admin Dashboard runs on a separate port (default: 8081) and requires authentication.

### Authentication

#### POST /login
Authenticate with the admin dashboard.

**Request (form-encoded):**
```
password=your_admin_password
```

**Response:** Sets session cookie and redirects to `/dashboard`.

---

#### GET /logout
End admin session.

**Response:** Clears session cookie and redirects to `/`.

---

### Dashboard Endpoints

All API endpoints require authentication (session cookie).

#### GET /api/status
Get relay status data.

---

#### GET /api/devices
Get list of connected devices.

---

#### GET /api/relays
Get list of connected relay nodes.

---

#### GET /api/rooms
Get list of chat rooms.

---

#### GET /api/scores
Get user reward/score data.

---

#### GET /api/bans
Get list of banned users.

---

#### GET /api/logs
Get server logs.

**Query Parameters:**
- `count` (optional) - Number of log entries (default: 50)

---

#### GET /api/config
Get current configuration.

---

### Admin Actions

#### POST /api/kick
Disconnect a device or relay.

**Request Body:**
```json
{
  "callsign": "X3ABC123"
}
```

---

#### POST /api/ban
Ban a user.

**Request Body:**
```json
{
  "callsign": "X1USER01",
  "reason": "Violation of rules"
}
```

---

#### POST /api/unban
Remove a ban.

**Request Body:**
```json
{
  "callsign": "X1USER01"
}
```

---

#### POST /api/broadcast
Send a message to all connected devices.

**Request Body:**
```json
{
  "message": "Server maintenance in 5 minutes"
}
```

---

#### POST /api/config
Update configuration.

**Request Body:**
```json
{
  "key": "maxConnectedDevices",
  "value": 500
}
```

---

#### POST /api/shutdown
Gracefully shutdown the relay server.

**Response:**
```json
{
  "success": true,
  "message": "Shutdown initiated"
}
```

---

## Error Handling

All endpoints return errors in a consistent JSON format:

```json
{
  "error": "Error description"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created (for POST requests)
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (admin endpoints)
- `404` - Not Found
- `500` - Internal Server Error
- `503` - Service Unavailable

---

## Configuration

Key configuration options affecting the API:

| Setting | Description | Default |
|---------|-------------|---------|
| `port` | Main server port | 8080 |
| `adminPort` | Admin dashboard port | 8081 |
| `enableAdminDashboard` | Enable admin API | true |
| `enableTileServer` | Enable map tile endpoint | true |
| `maxConnectedDevices` | Maximum device connections | 1000 |
| `httpRequestTimeout` | Proxy request timeout (seconds) | 30 |

---

## Examples

### Connect and Register a Device (WebSocket)

```javascript
const ws = new WebSocket('ws://relay.example.com:8080/');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'REGISTER',
    callsign: 'X3MYDEVICE'
  }));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  console.log('Received:', msg.type);
};
```

### Search Collections (HTTP)

```bash
curl "http://relay.example.com:8080/search?q=document&limit=10"
```

### Post Chat Message (HTTP)

```bash
curl -X POST "http://relay.example.com:8080/api/chat/rooms/general/messages" \
  -H "Content-Type: application/json" \
  -d '{"callsign": "X1USER01", "content": "Hello from curl!"}'
```

### Proxy Request to Device (HTTP)

```bash
curl "http://relay.example.com:8080/device/X3ABC123/api/status"
```
