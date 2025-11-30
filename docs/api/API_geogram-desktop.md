# Geogram Desktop API Documentation

This document describes the HTTP and WebSocket APIs provided by the Geogram Desktop application.

## Table of Contents

- [Overview](#overview)
- [HTTP API Server](#http-api-server)
  - [Status & Information](#status--information)
  - [Log Access](#log-access)
  - [File Browser](#file-browser)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection & Authentication](#connection--authentication)
  - [Device Messages](#device-messages)
  - [Update Notifications](#update-notifications)
- [Relay Chat API](#relay-chat-api)
- [Network Discovery](#network-discovery)
- [Security](#security)
- [Error Handling](#error-handling)

---

## Overview

Geogram Desktop is a Flutter-based desktop application that:

1. **Serves a local HTTP API** (port 45678) for accessing logs and collections
2. **Connects to relays via WebSocket** as a client device
3. **Uses NOSTR protocol** for authentication and chat messaging

**Local API Server:** `http://localhost:45678`

**WebSocket Connection:** Connects to relay servers (e.g., `ws://relay.example.com:8080/`)

---

## HTTP API Server

The local HTTP API server runs on port **45678** and is accessible from the network.

### Status & Information

#### GET /
Returns service information and available endpoints.

**Response:**
```json
{
  "service": "Geogram Desktop",
  "version": "1.0.0",
  "type": "geogram-desktop",
  "callsign": "X1ABC123",
  "hostname": "my-computer",
  "endpoints": {
    "/log": "Get log entries (supports ?filter=text&limit=100)",
    "/files": "Browse collections (supports ?path=subfolder)",
    "/files/content": "Get file content (supports ?path=file/path)"
  }
}
```

---

#### GET /api/status
#### GET /relay/status
Returns desktop status (compatible with relay discovery).

**Response:**
```json
{
  "service": "Geogram Desktop",
  "version": "1.0.0",
  "type": "desktop",
  "status": "online",
  "callsign": "X1ABC123",
  "name": "X1ABC123",
  "hostname": "my-computer",
  "port": 45678
}
```

---

### Log Access

#### GET /log
Retrieve application log entries with optional filtering.

**Query Parameters:**
- `filter` (optional) - Text to filter log messages (case-insensitive)
- `limit` (optional) - Maximum number of log entries to return

**Response:**
```json
{
  "total": 150,
  "filter": "relay",
  "limit": 50,
  "logs": [
    "[2024-01-15 10:30:00] RelayService: Connected to relay",
    "[2024-01-15 10:30:01] WebSocket: Connection established",
    "..."
  ]
}
```

**Error Response (400):**
```json
{
  "error": "Invalid limit parameter"
}
```

---

### File Browser

#### GET /files
Browse collections directory. Only public collections are accessible.

**Query Parameters:**
- `path` (optional) - Relative path within collections directory

**Response (Directory Listing):**
```json
{
  "path": "/documents",
  "base": "/home/user/Documents/geogram/collections",
  "total": 5,
  "entries": [
    {
      "name": "photos",
      "type": "directory",
      "isDirectory": true,
      "size": 1048576
    },
    {
      "name": "readme.txt",
      "type": "file",
      "isDirectory": false,
      "size": 1024
    }
  ]
}
```

**Response (File Info):**
```json
{
  "path": "documents/readme.txt",
  "type": "file",
  "name": "readme.txt",
  "size": 1024,
  "modified": "2024-01-15T10:30:00.000Z"
}
```

**Error Responses:**
- `403` - Access denied (private collection or protected path)
- `404` - Path not found

```json
{
  "error": "Access denied: collection is not public"
}
```

---

#### GET /files/content
Get the content of a specific file.

**Query Parameters:**
- `path` (required) - Relative path to the file

**Response:**
Plain text file content with header:
```
Content-Type: text/plain; charset=utf-8
```

**Error Responses:**
- `400` - Missing path parameter or path is a directory
- `403` - Access denied (protected path or private collection)
- `404` - File not found

```json
{
  "error": "Missing path parameter"
}
```

---

## WebSocket Protocol

Geogram Desktop connects to relay servers as a client device using WebSocket with JSON messaging.

### Connection & Authentication

#### hello (Desktop → Relay)
Initial handshake message with NOSTR-signed authentication.

**Message Format:**
```json
{
  "type": "hello",
  "event": {
    "kind": 24150,
    "pubkey": "hex_public_key_64_chars",
    "created_at": 1705320000,
    "tags": [
      ["callsign", "X1ABC123"],
      ["npub", "npub1..."]
    ],
    "content": "{\"callsign\":\"X1ABC123\",\"npub\":\"npub1...\"}",
    "id": "event_id_hex_64_chars",
    "sig": "schnorr_signature_hex_128_chars"
  }
}
```

**Event Fields:**
- `kind`: 24150 (Geogram hello event type)
- `pubkey`: Hex-encoded public key (64 characters)
- `created_at`: Unix timestamp (seconds)
- `tags`: Array of tag arrays
- `content`: JSON-encoded content string
- `id`: SHA256 hash of serialized event
- `sig`: BIP-340 Schnorr signature

---

#### hello_ack (Relay → Desktop)
Relay's response to the hello handshake.

**Success Response:**
```json
{
  "type": "hello_ack",
  "success": true,
  "relay_id": "relay-X3RELAY1-1705320000",
  "message": "Welcome X1ABC123"
}
```

**Failure Response:**
```json
{
  "type": "hello_ack",
  "success": false,
  "message": "Invalid signature"
}
```

---

### Device Messages

#### PING / PONG
Keep-alive heartbeat messages sent every 60 seconds.

**Desktop → Relay:**
```json
{
  "type": "PING"
}
```

**Relay → Desktop:**
```json
{
  "type": "PONG"
}
```

---

#### COLLECTIONS_REQUEST (Relay → Desktop)
Relay requests list of available collections.

```json
{
  "type": "COLLECTIONS_REQUEST",
  "requestId": "uuid-request-id"
}
```

---

#### COLLECTIONS_RESPONSE (Desktop → Relay)
Desktop responds with list of public/restricted collection names.

```json
{
  "type": "COLLECTIONS_RESPONSE",
  "requestId": "uuid-request-id",
  "collections": ["www", "documents", "photos"]
}
```

**Note:** Private collections are automatically filtered out.

---

#### COLLECTION_FILE_REQUEST (Relay → Desktop)
Relay requests a specific file from a collection.

```json
{
  "type": "COLLECTION_FILE_REQUEST",
  "requestId": "uuid-request-id",
  "collectionName": "www",
  "fileName": "collection"
}
```

**Valid fileName values:**
- `collection` - Returns `collection.js`
- `tree` - Returns `extra/tree.json`
- `data` - Returns `extra/data.js`

---

#### COLLECTION_FILE_RESPONSE (Desktop → Relay)
Desktop responds with file content.

```json
{
  "type": "COLLECTION_FILE_RESPONSE",
  "requestId": "uuid-request-id",
  "collectionName": "www",
  "fileName": "collection.js",
  "fileContent": "var collection = {...};"
}
```

---

#### HTTP_REQUEST (Relay → Desktop)
Relay proxies an HTTP request for www collection files.

```json
{
  "type": "HTTP_REQUEST",
  "requestId": "uuid-request-id",
  "method": "GET",
  "path": "/collections/www/index.html",
  "headers": "{\"Accept\": \"text/html\"}",
  "body": ""
}
```

**Path Format:** `/collections/{collectionName}/{filePath}`

---

#### HTTP_RESPONSE (Desktop → Relay)
Desktop responds with the requested file.

```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "uuid-request-id",
  "statusCode": 200,
  "responseHeaders": "{\"Content-Type\": \"text/html\"}",
  "responseBody": "base64_encoded_content_or_plain_text",
  "isBase64": true
}
```

**Status Codes:**
- `200` - Success
- `403` - Forbidden (private collection)
- `404` - File not found
- `500` - Internal server error

**Content Types Supported:**
| Extension | Content-Type |
|-----------|--------------|
| html, htm | text/html |
| css | text/css |
| js | application/javascript |
| json | application/json |
| png | image/png |
| jpg, jpeg | image/jpeg |
| gif | image/gif |
| svg | image/svg+xml |
| ico | image/x-icon |
| txt | text/plain |
| (other) | application/octet-stream |

---

### Update Notifications

#### UPDATE (Relay → Desktop)
Lightweight notification when content is updated on the relay. This is a plain string, not JSON.

**Format:** `UPDATE:{callsign}:{collectionType}:{path}`

**Example:**
```
UPDATE:X1USER01:blog:/updates
```

**Parsed Fields:**
- `callsign` - Source device callsign
- `collectionType` - Type of collection (e.g., "blog", "chat")
- `path` - Updated path

---

## Relay Chat API

Geogram Desktop can interact with relay chat rooms via HTTP or WebSocket.

### HTTP Chat Endpoints

These endpoints are called on the connected relay server.

#### GET /api/chat/rooms
Fetch available chat rooms from the relay.

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
  ]
}
```

---

#### GET /api/chat/rooms/{roomId}/messages
Fetch messages from a chat room.

**Query Parameters:**
- `limit` (optional) - Maximum messages (default: 50)

**Response:**
```json
{
  "messages": [
    {
      "id": "msg-uuid",
      "content": "Hello, world!",
      "callsign": "X1USER01",
      "pubkey": "hex_pubkey",
      "timestamp": 1705320000,
      "event_id": "nostr_event_id",
      "signature": "schnorr_signature"
    }
  ]
}
```

---

#### POST /api/chat/rooms/{roomId}/messages
Post a message to a chat room with NOSTR signature.

**Request Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "callsign": "X1ABC123",
  "content": "Hello from desktop!",
  "npub": "npub1...",
  "pubkey": "hex_public_key_64_chars",
  "event_id": "nostr_event_id_64_chars",
  "signature": "schnorr_signature_128_chars",
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

---

### WebSocket Chat Messages (NOSTR Protocol)

When connected via WebSocket, desktop uses NOSTR protocol for chat.

#### nostr_event (Desktop → Relay)
Send a chat message as a NOSTR event.

```json
{
  "nostr_event": ["EVENT", {
    "id": "event_id_hex_64_chars",
    "pubkey": "hex_public_key_64_chars",
    "created_at": 1705320000,
    "kind": 1,
    "tags": [
      ["t", "chat"],
      ["room", "general"],
      ["callsign", "X1ABC123"]
    ],
    "content": "Hello from desktop!",
    "sig": "schnorr_signature_128_128_chars"
  }]
}
```

**NOSTR Event Structure:**
- `id`: SHA256 hash of serialized event data
- `pubkey`: Sender's public key (hex)
- `created_at`: Unix timestamp (seconds)
- `kind`: 1 (text note)
- `tags`: Metadata tags
- `content`: Message text
- `sig`: BIP-340 Schnorr signature

---

#### nostr_req (Desktop → Relay)
Subscribe to chat room messages.

```json
{
  "nostr_req": ["REQ", "subscription-id-123", {
    "kinds": [1],
    "#room": ["general"],
    "limit": 50
  }]
}
```

---

#### nostr_close (Desktop → Relay)
Unsubscribe from a chat subscription.

```json
{
  "nostr_close": ["CLOSE", "subscription-id-123"]
}
```

---

## Network Discovery

Geogram Desktop can discover other devices on the local network.

### Discovery Process

1. Scans local network IP ranges
2. Checks common ports: 80, 8080, 8081, 45678, 3000, 5000
3. Sends HTTP requests to detect Geogram devices

### Detection Endpoints

The discovery service checks these endpoints on discovered IPs:

#### GET http://{ip}:{port}/api/status
#### GET http://{ip}:{port}/relay/status
#### GET http://{ip}:{port}/

**Expected Response (Geogram Device):**
```json
{
  "service": "Geogram Relay Server",
  "callsign": "X3RELAY1",
  "name": "My Relay",
  "version": "1.0.0",
  "description": "Local relay server",
  "connected_devices": 5,
  "location": {
    "city": "New York",
    "country": "United States"
  }
}
```

Or for desktop:
```json
{
  "service": "Geogram Desktop",
  "type": "desktop",
  "callsign": "X1USER01",
  "hostname": "desktop-pc"
}
```

---

## Security

### Protected Paths

The following paths are blocked from API access:

- `extra/` - Contains security configuration
- `security.json`, `security.txt`
- `.security`
- `.git`, `.gitignore`
- Any path starting with `.` (hidden files)

### Collection Visibility

Collections have three visibility levels:

| Visibility | API Access | Description |
|------------|------------|-------------|
| `public` | Allowed | Anyone can access |
| `restricted` | Allowed | Shared with authentication |
| `private` | Blocked | Not shared via API |

The visibility is defined in `{collection}/extra/security.json`:
```json
{
  "visibility": "public"
}
```

### NOSTR Authentication

- All hello handshakes are signed with BIP-340 Schnorr signatures
- Chat messages include NOSTR event signatures
- Signatures are verified server-side before acceptance

---

## Error Handling

### HTTP Error Responses

All errors return JSON with an `error` field:

```json
{
  "error": "Description of the error"
}
```

**Common Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad Request (invalid parameters) |
| 403 | Forbidden (access denied) |
| 404 | Not Found |
| 500 | Internal Server Error |

### WebSocket Error Handling

- Connection errors trigger automatic reconnection (10-second intervals)
- PING messages sent every 60 seconds to prevent idle timeout
- Reconnection attempts preserve the relay URL

---

## Configuration

### Default Settings

| Setting | Value | Description |
|---------|-------|-------------|
| API Port | 45678 | Local HTTP API server port |
| Ping Interval | 60 seconds | WebSocket keep-alive interval |
| Reconnect Interval | 10 seconds | Auto-reconnection check interval |
| Collections Path | `~/Documents/geogram/collections` | Default collections directory |

---

## Examples

### Connect to Relay (Dart)

```dart
final wsService = WebSocketService();
final success = await wsService.connectAndHello('ws://relay.example.com:8080');

if (success) {
  print('Connected to relay!');
}
```

### Fetch Collections via HTTP

```bash
curl "http://localhost:45678/files"
```

### Post Chat Message via HTTP

```bash
curl -X POST "http://relay.example.com:8080/api/chat/rooms/general/messages" \
  -H "Content-Type: application/json" \
  -d '{
    "callsign": "X1ABC123",
    "content": "Hello!",
    "npub": "npub1...",
    "pubkey": "hex_pubkey",
    "event_id": "event_id",
    "signature": "sig",
    "created_at": 1705320000
  }'
```

### Browse Logs

```bash
curl "http://localhost:45678/log?filter=relay&limit=50"
```

### Get File Content

```bash
curl "http://localhost:45678/files/content?path=documents/readme.txt"
```
