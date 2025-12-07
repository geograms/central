# Geogram API Documentation

This document describes the HTTP and WebSocket APIs for the Geogram network, covering both **Relay Server** and **Desktop Client** endpoints.

## Table of Contents

- [Overview](#overview)
- [Common Concepts](#common-concepts)
  - [Callsigns](#callsigns)
  - [NOSTR Protocol](#nostr-protocol)
  - [Callsign-Scoped API](#callsign-scoped-api)
- [Relay Server API](#relay-server-api)
  - [Status & Information](#status--information)
  - [Device Proxy](#device-proxy)
  - [Blog API](#blog-api)
  - [Collections & Search](#collections--search)
  - [Groups API](#groups-api)
  - [Map Tiles](#map-tiles)
  - [SSL/ACME](#sslacme)
  - [CLI API](#cli-api)
  - [Admin Dashboard](#admin-dashboard-api)
- [Desktop Client API](#desktop-client-api)
  - [Desktop Status](#desktop-status)
  - [Log Access](#log-access)
  - [File Browser](#file-browser)
- [Chat API](#chat-api)
  - [HTTP Endpoints](#http-chat-endpoints)
  - [Chat File Caching](#chat-file-caching)
  - [WebSocket Messages](#websocket-chat-messages)
  - [Chat Storage](#chat-storage)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection & Authentication](#connection--authentication)
  - [Device Messages](#device-messages)
  - [Remote Device Browsing](#remote-device-browsing)
  - [Relay-to-Relay Messages](#relay-to-relay-messages)
  - [Update Notifications](#update-notifications)
- [Network Discovery](#network-discovery)
- [Security](#security)
- [Error Handling](#error-handling)
- [Configuration](#configuration)
- [Examples](#examples)

---

## Overview

The Geogram network consists of two main components:

### Relay Server
A server that coordinates device connections and provides shared services:
- **Main Server** (default port 8080): HTTP and WebSocket endpoints
- **Admin Dashboard** (default port 8081): Web administration interface
- Base URL: `http://relay-host:8080`
- WebSocket: `ws://relay-host:8080/`

### Desktop Client
A Flutter application that serves a local API and connects to relays:
- **Local API** (port 45678): HTTP endpoints for logs and collections
- Connects to relays as a WebSocket client
- Base URL: `http://localhost:45678`

---

## Common Concepts

### Callsigns

Every device and relay in the Geogram network has a unique callsign derived from its NOSTR public key (npub):

| Prefix | Type | Example |
|--------|------|---------|
| `X1` | Desktop/Mobile client | `X1ABC123` |
| `X2` | Reserved | - |
| `X3` | Relay server | `X3RELAY1` |

Callsigns are **case-insensitive** in API paths but typically displayed in uppercase.

### NOSTR Protocol

Geogram uses NOSTR (Notes and Other Stuff Transmitted by Relays) for:
- **Authentication**: Hello handshakes are signed with BIP-340 Schnorr signatures
- **Chat messages**: Messages include NOSTR event signatures for verification
- **Identity**: Public keys (npub) serve as the basis for callsigns

**NOSTR Event Structure:**
```json
{
  "id": "sha256_hash_of_serialized_event_64_chars",
  "pubkey": "hex_public_key_64_chars",
  "created_at": 1705320000,
  "kind": 1,
  "tags": [["t", "chat"], ["room", "general"]],
  "content": "Message text",
  "sig": "bip340_schnorr_signature_128_chars"
}
```

### Callsign-Scoped API

APIs that access device-specific data use callsign-scoped paths:

```
/{callsign}/api/{endpoint}
```

This allows:
- Multiple profiles per device
- Relay to store data for connected devices
- Clear ownership of data paths

**Example:**
```
GET /X3RELAY1/api/chat/rooms
GET /X1USER01/api/chat/rooms/general/messages
```

---

## Relay Server API

### Status & Information

#### GET /
Returns the relay home page (HTML interface with status and connected devices).

---

#### GET /api/status
#### GET /status
Returns detailed relay status information.

**Response:**
```json
{
  "service": "Geogram Relay Server",
  "version": "1.5.2",
  "status": "online",
  "started_at": "2024-01-15T10:30:00Z",
  "uptime_hours": 24,
  "port": 8080,
  "callsign": "X3ABC123",
  "name": "Downtown Emergency Relay",
  "description": "Geogram relay for emergency services coordination",
  "connected_devices": 5,
  "max_devices": 1000,
  "chat_rooms": 3,
  "devices": [
    {
      "callsign": "X1USER01",
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
    "country": "United States"
  }
}
```

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
      "callsign": "X1USER01",
      "uptime_seconds": 3600,
      "idle_seconds": 60,
      "connected_at": "2024-01-15T11:30:00Z"
    }
  ]
}
```

---

#### GET /api/stats
Returns server statistics.

**Response:**
```json
{
  "uptime_seconds": 86400,
  "total_connections": 150,
  "total_messages": 1250,
  "total_tile_requests": 5000,
  "memory_usage_mb": 128
}
```

---

#### GET /api/devices
List all connected devices.

**Response:**
```json
{
  "devices": [
    {
      "callsign": "X1USER01",
      "connected_at": "2024-01-15T11:30:00Z",
      "uptime_seconds": 3600
    }
  ],
  "count": 1
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
  "callsign": "X1USER01",
  "connected": true,
  "uptime": 3600,
  "idleTime": 60
}
```

**Response (404 - Device not connected):**
```json
{
  "callsign": "X1USER01",
  "connected": false,
  "error": "Device not connected"
}
```

---

### Device Proxy

#### ANY /device/{callsign}/*
Proxy HTTP requests to a connected device. Supports all HTTP methods.

**Path Parameters:**
- `callsign` - Device callsign
- `*` - Path to forward to the device

**Example:**
```
GET /device/X1USER01/files
```

The relay forwards the request to the device over WebSocket and returns the response.

---

#### GET /{callsign}
#### GET /{callsign}/*
Serve files from a device's `www` collection (website hosting).

**Example:**
```
GET /X1USER01/           -> Serves index.html from www collection
GET /X1USER01/style.css  -> Serves style.css from www collection
```

---

### Blog API

The relay provides APIs for accessing blog posts from connected devices. This includes both external HTTP access and device-to-device communication via WebSocket.

#### External HTTP Access

##### GET /{nickname}/blog/{filename}.html
Fetch a rendered HTML blog post from a connected device.

**Path Parameters:**
- `nickname` - Device nickname or callsign (case-insensitive)
- `filename` - Blog post filename (e.g., `2025-12-04_hello-everyone`)

**Example:**
```
GET /embaixada/blog/2025-12-04_hello-everyone.html
```

**Request Flow:**
1. Relay receives HTTP request for blog post
2. Relay finds connected device by nickname/callsign
3. Relay sends `HTTP_REQUEST` WebSocket message to device
4. Device reads blog markdown, converts to HTML
5. Device sends `HTTP_RESPONSE` back to relay
6. Relay returns HTML to the client

**Response (200 - Success):**
Returns a complete HTML page with the blog post content rendered from markdown, including:
- Styled HTML with dark theme
- Post title and date metadata
- Author information
- Rendered markdown content
- Footer with geogram.radio link

**Response (404 - Not Found):**
```json
{
  "error": "Blog post not found"
}
```

**Response (503 - Device Not Connected):**
```json
{
  "error": "User not found"
}
```

---

#### Remote Device Blog Access

Connected devices can browse and read blog posts from other connected devices through the relay using WebSocket messages.

##### LIST_BLOG_POSTS (Request blog list from remote device)

**Request (Device A → Relay → Device B):**
```json
{
  "type": "REMOTE_REQUEST",
  "targetCallsign": "X1TARGET",
  "requestId": "unique-request-id",
  "request": {
    "type": "LIST_BLOG_POSTS",
    "collectionName": "default",
    "year": 2025,
    "limit": 20,
    "offset": 0
  }
}
```

**Response (Device B → Relay → Device A):**
```json
{
  "type": "REMOTE_RESPONSE",
  "sourceCallsign": "X1TARGET",
  "requestId": "unique-request-id",
  "response": {
    "type": "BLOG_POST_LIST",
    "posts": [
      {
        "filename": "2025-12-04_hello-everyone.md",
        "title": "Hello Everyone",
        "author": "CR7BBQ",
        "date": "2025-12-04",
        "status": "published",
        "tags": ["welcome", "introduction"],
        "description": "My first blog post"
      }
    ],
    "total": 1,
    "hasMore": false
  }
}
```

##### GET_BLOG_POST (Request specific blog post from remote device)

**Request (Device A → Relay → Device B):**
```json
{
  "type": "REMOTE_REQUEST",
  "targetCallsign": "X1TARGET",
  "requestId": "unique-request-id",
  "request": {
    "type": "GET_BLOG_POST",
    "collectionName": "default",
    "filename": "2025-12-04_hello-everyone.md",
    "format": "markdown"
  }
}
```

**Format Options:**
- `markdown` - Returns raw markdown content
- `html` - Returns rendered HTML
- `metadata` - Returns only metadata (no content)

**Response (Device B → Relay → Device A):**
```json
{
  "type": "REMOTE_RESPONSE",
  "sourceCallsign": "X1TARGET",
  "requestId": "unique-request-id",
  "response": {
    "type": "BLOG_POST",
    "post": {
      "filename": "2025-12-04_hello-everyone.md",
      "title": "Hello Everyone",
      "author": "CR7BBQ",
      "date": "2025-12-04",
      "status": "published",
      "tags": ["welcome", "introduction"],
      "description": "My first blog post",
      "content": "# Hello Everyone\n\nWelcome to my blog...",
      "npub": "npub1abc123...",
      "signature": "sig123...",
      "comments": [
        {
          "author": "X135AS",
          "timestamp": "2025-12-04T10:15:30Z",
          "content": "Great post!"
        }
      ]
    }
  }
}
```

---

#### Relay-to-Device Protocol

The relay communicates with devices using these internal message types:

**HTTP_REQUEST (Relay → Device):**
```json
{
  "type": "HTTP_REQUEST",
  "requestId": "unique-request-id",
  "method": "GET",
  "path": "/api/blog/2025-12-04_hello-everyone.html"
}
```

**HTTP_RESPONSE (Device → Relay):**
```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "unique-request-id",
  "statusCode": 200,
  "contentType": "text/html",
  "body": "<!DOCTYPE html>..."
}
```

---

#### Local Device API Endpoints

When a device runs its local HTTP server, these endpoints are available:

##### GET /api/blog
List all published blog posts from all collections.

**Response:**
```json
{
  "posts": [
    {
      "collection": "default",
      "filename": "2025-12-04_hello-everyone.md",
      "title": "Hello Everyone",
      "author": "CR7BBQ",
      "date": "2025-12-04",
      "status": "published",
      "tags": ["welcome"]
    }
  ]
}
```

##### GET /api/blog/{collection}
List blog posts from a specific collection.

**Path Parameters:**
- `collection` - Collection name

##### GET /api/blog/{collection}/{filename}
Get a specific blog post.

**Path Parameters:**
- `collection` - Collection name
- `filename` - Blog post filename

**Query Parameters:**
- `format` - Response format: `json` (default), `html`, `markdown`

**Response (JSON format):**
```json
{
  "filename": "2025-12-04_hello-everyone.md",
  "title": "Hello Everyone",
  "author": "CR7BBQ",
  "date": "2025-12-04",
  "status": "published",
  "tags": ["welcome"],
  "content": "# Hello Everyone\n\nWelcome to my blog...",
  "comments": []
}
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
      "callsign": "X1USER01",
      "collection": "documents",
      "file": "example.txt",
      "score": 0.95
    }
  ]
}
```

---

### Groups API

#### GET /api/groups
List all active groups on the relay.

**Response:**
```json
{
  "relay": "X3RELAY1",
  "groups": [
    {
      "name": "npub1abc123...",
      "title": "Emergency Response Team",
      "description": "Local emergency coordination",
      "type": "association",
      "member_count": 15
    }
  ],
  "count": 1
}
```

---

#### GET /api/groups/{groupId}
Get detailed information about a specific group.

**Response:**
```json
{
  "name": "npub1abc123...",
  "title": "Emergency Response Team",
  "type": "association",
  "member_count": 15,
  "areas": [
    {
      "id": "area_123",
      "name": "Downtown Coverage",
      "radius_km": 25.0,
      "center": {"latitude": 40.7128, "longitude": -74.0060}
    }
  ]
}
```

**Group Types:**
`association`, `friends`, `authority_police`, `authority_fire`, `authority_civil_protection`, `authority_military`, `health_hospital`, `health_clinic`, `health_emergency`, `admin_townhall`, `admin_regional`, `admin_national`, `infrastructure_utilities`, `infrastructure_transport`, `education_school`, `education_university`, `collection_moderator`

---

#### GET /api/groups/{groupId}/members
Get members of a specific group.

**Response:**
```json
{
  "group_id": "npub1abc123...",
  "members": [
    {
      "callsign": "X1ADMIN01",
      "npub": "npub1xyz...",
      "role": "admin",
      "joined": "2024-01-15 10:30_00"
    }
  ],
  "count": 1
}
```

**Member Roles:** `admin`, `moderator`, `contributor`, `guest`

---

### Map Tiles

#### GET /tiles/{callsign}/{z}/{x}/{y}.png
Serve cached map tiles.

**Path Parameters:**
- `callsign` - Requesting device callsign
- `z` - Zoom level (0-18)
- `x` - Tile X coordinate
- `y` - Tile Y coordinate

**Query Parameters:**
- `layer` (optional) - `standard` (default, OSM) or `satellite` (Esri)

**Response:** PNG image

**Caching:**
- Tiles are cached globally (not per-device)
- Memory + disk cache
- Configurable max zoom level

---

### SSL/ACME

#### GET /.well-known/acme-challenge/{token}
ACME HTTP-01 challenge endpoint for Let's Encrypt SSL certificates.

---

### CLI API

#### POST /api/cli
Execute a CLI command remotely.

**Request:**
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

---

### Admin Dashboard API

The Admin Dashboard runs on a separate port (default: 8081) and requires authentication.

#### POST /login
Authenticate with the admin dashboard.

#### GET /logout
End admin session.

#### Authenticated Endpoints:
- `GET /api/status` - Relay status
- `GET /api/devices` - Connected devices
- `GET /api/relays` - Connected relays
- `GET /api/rooms` - Chat rooms
- `GET /api/logs?count=50` - Server logs
- `GET /api/config` - Configuration
- `POST /api/kick` - Disconnect device
- `POST /api/ban` - Ban user
- `POST /api/unban` - Remove ban
- `POST /api/broadcast` - Send message to all
- `POST /api/config` - Update config
- `POST /api/shutdown` - Shutdown server

---

## Desktop Client API

The desktop client runs a local HTTP server on port **45678**.

### Desktop Status

#### GET /
Returns service information and available endpoints.

**Response:**
```json
{
  "service": "Geogram Desktop",
  "version": "1.5.2",
  "type": "geogram-desktop",
  "callsign": "X1ABC123",
  "hostname": "my-computer",
  "endpoints": {
    "/log": "Get log entries",
    "/files": "Browse collections",
    "/files/content": "Get file content"
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
  "version": "1.5.2",
  "type": "desktop",
  "status": "online",
  "callsign": "X1ABC123",
  "hostname": "my-computer",
  "port": 45678
}
```

---

### Log Access

#### GET /log
Retrieve application log entries.

**Query Parameters:**
- `filter` (optional) - Text filter (case-insensitive)
- `limit` (optional) - Maximum entries

**Response:**
```json
{
  "total": 150,
  "filter": "relay",
  "limit": 50,
  "logs": [
    "[2024-01-15 10:30:00] RelayService: Connected to relay",
    "..."
  ]
}
```

---

### File Browser

#### GET /files
Browse collections directory (public collections only).

**Query Parameters:**
- `path` (optional) - Relative path within collections

**Response (Directory):**
```json
{
  "path": "/documents",
  "total": 5,
  "entries": [
    {"name": "photos", "type": "directory", "isDirectory": true},
    {"name": "readme.txt", "type": "file", "size": 1024}
  ]
}
```

---

#### GET /files/content
Get file content.

**Query Parameters:**
- `path` (required) - Relative file path

**Response:** Plain text file content

**Error Responses:**
- `403` - Access denied (private collection)
- `404` - File not found

---

## Chat API

The Chat API uses **callsign-scoped paths** to support multiple profiles and clear data ownership.

**API Path Pattern:**
```
/{callsign}/api/chat/rooms
/{callsign}/api/chat/rooms/{roomId}/messages
```

### HTTP Chat Endpoints

#### GET /{callsign}/api/chat/rooms
List all chat rooms for a callsign.

**Response:**
```json
{
  "callsign": "X3RELAY1",
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

#### GET /{callsign}/api/chat/rooms/{roomId}/messages
Get messages from a chat room.

**Path Parameters:**
- `callsign` - Owner callsign
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
      "id": "msg-uuid",
      "timestamp": "2024-01-15T12:00:00Z",
      "callsign": "X1USER01",
      "content": "Hello, world!",
      "npub": "npub1...",
      "pubkey": "hex_pubkey",
      "event_id": "nostr_event_id",
      "signature": "schnorr_signature"
    }
  ],
  "count": 1
}
```

---

#### POST /{callsign}/api/chat/rooms/{roomId}/messages
Post a message to a chat room.

**Request Body (with NOSTR signature):**
```json
{
  "callsign": "X1USER01",
  "content": "Hello, world!",
  "npub": "npub1...",
  "pubkey": "hex_pubkey_64_chars",
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

**Error Responses:**
- `400` - Missing callsign, content, or invalid signature
- `404` - Room not found

---

#### POST /api/relay/send
Send a message from the relay itself (relay-signed NOSTR event).

**Request:**
```json
{
  "room": "general",
  "content": "Announcement from relay",
  "callsign": "X3RELAY1"
}
```

---

### Chat File Caching

These endpoints enable clients to download raw chat files for offline caching. By downloading the original files rather than reconstructing messages, clients preserve all NOSTR verification metadata (signatures, event IDs, public keys).

#### GET /{callsign}/api/chat/rooms/{roomId}/files
List all available chat files for a room (used for client-side caching).

**Path Parameters:**
- `callsign` - Owner callsign
- `roomId` - Chat room ID

**Response:**
```json
{
  "room_id": "general",
  "relay": "X3RELAY1",
  "files": [
    {
      "year": "2024",
      "filename": "2024-01-15_chat.txt",
      "size": 4096,
      "modified": 1705320000
    },
    {
      "year": "2024",
      "filename": "2024-01-16_chat.txt",
      "size": 2048,
      "modified": 1705406400
    }
  ],
  "count": 2
}
```

**Use Case:**
Clients use this endpoint to discover which chat files are available for a room, then selectively download files they don't have cached locally. This enables efficient offline chat viewing by preserving the original file format with all NOSTR verification metadata.

---

#### GET /{callsign}/api/chat/rooms/{roomId}/file/{year}/{filename}
Get the raw content of a specific chat file.

**Path Parameters:**
- `callsign` - Owner callsign
- `roomId` - Chat room ID
- `year` - Year folder (e.g., "2024")
- `filename` - Chat file name (must match pattern `YYYY-MM-DD_chat.txt`)

**Response:**
Returns the raw text content of the chat file with `Content-Type: text/plain; charset=UTF-8`.

**Example Response:**
```
# X3RELAY1:general
# Chat room: General

> 2024-01-15 12:00:00 -- X1USER01 [npub1abc...]
Hello, world!
{sig:abc123..., event_id:def456...}

> 2024-01-15 12:01:30 -- X2USER02 [npub1xyz...]
Hi there!
{sig:ghi789..., event_id:jkl012...}
```

**Error Responses:**
- `400` - Invalid filename format (path traversal protection)
- `404` - File not found

**Security:**
The filename parameter is validated to prevent path traversal attacks. Only files matching the pattern `YYYY-MM-DD_chat.txt` are allowed.

**Use Case:**
Clients download raw chat files to cache locally for offline viewing. The raw format preserves:
- NOSTR signature verification data (`{sig:..., event_id:...}`)
- Public key references (`[npub1...]`)
- Original timestamps and formatting
- All messages from the day, not just recent ones

---

### WebSocket Chat Messages

#### nostr_event (Client -> Relay)
Send a chat message as a NOSTR event via WebSocket.

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
      ["callsign", "X1USER01"]
    ],
    "content": "Hello from desktop!",
    "sig": "schnorr_signature_128_chars"
  }]
}
```

The relay verifies the BIP-340 Schnorr signature before accepting the message.

---

#### nostr_req (Client -> Relay)
Subscribe to chat room messages.

```json
{
  "nostr_req": ["REQ", "subscription-id", {
    "kinds": [1],
    "#room": ["general"],
    "limit": 50
  }]
}
```

---

#### nostr_close (Client -> Relay)
Unsubscribe from a subscription.

```json
{
  "nostr_close": ["CLOSE", "subscription-id"]
}
```

---

### Chat Storage

Chat messages are stored in human-readable text files:

**Path:** `/devices/{callsign}/chat/{roomId}/{year}/{date}_chat.txt`

**Example:** `/devices/X3RELAY1/chat/general/2024/2024-01-15_chat.txt`

**Format:**
```
# X3RELAY1:general
# Chat room: General

> 2024-01-15 12:00:00 -- X1USER01 [npub1abc...]
Hello, world!
{sig:abc123..., event_id:def456...}

> 2024-01-15 12:01:30 -- X2USER02 [npub1xyz...]
Hi there!
{sig:ghi789..., event_id:jkl012...}
```

---

## WebSocket Protocol

### Connection & Authentication

#### hello (Client -> Relay)
Initial handshake with NOSTR-signed authentication.

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

---

#### hello_ack (Relay -> Client)
Response to hello handshake.

**Success:**
```json
{
  "type": "hello_ack",
  "success": true,
  "relay_id": "relay-X3RELAY1-1705320000",
  "message": "Welcome X1ABC123"
}
```

**Failure:**
```json
{
  "type": "hello_ack",
  "success": false,
  "message": "Invalid signature"
}
```

---

#### REGISTER
Register a device (alternative to hello).

```json
{
  "type": "REGISTER",
  "callsign": "X1ABC123"
}
```

---

### Device Messages

#### PING / PONG
Keep-alive heartbeat (sent every 60 seconds).

```json
{"type": "PING"}
{"type": "PONG"}
```

---

#### COLLECTIONS_REQUEST / COLLECTIONS_RESPONSE
Request list of collections from a device.

**Request:**
```json
{
  "type": "COLLECTIONS_REQUEST",
  "requestId": "uuid"
}
```

**Response:**
```json
{
  "type": "COLLECTIONS_RESPONSE",
  "requestId": "uuid",
  "collections": ["www", "documents", "photos"]
}
```

---

#### COLLECTION_FILE_REQUEST / COLLECTION_FILE_RESPONSE
Request a specific file from a collection.

**Request:**
```json
{
  "type": "COLLECTION_FILE_REQUEST",
  "requestId": "uuid",
  "collectionName": "documents",
  "fileName": "tree"
}
```

**Valid `fileName` values:**
- `collection` - Returns `collection.js`
- `tree` - Returns `extra/tree.json`
- `data` - Returns `extra/data.js`

**Response:**
```json
{
  "type": "COLLECTION_FILE_RESPONSE",
  "requestId": "uuid",
  "collectionName": "documents",
  "fileName": "tree.json",
  "fileContent": "[{\"name\":\"subdir\",\"type\":\"folder\"}]"
}
```

---

#### HTTP_REQUEST / HTTP_RESPONSE
Proxy HTTP requests through WebSocket.

**Request:**
```json
{
  "type": "HTTP_REQUEST",
  "requestId": "uuid",
  "method": "GET",
  "path": "/collections/documents/readme.txt",
  "headers": "",
  "body": ""
}
```

**Response:**
```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "uuid",
  "statusCode": 200,
  "responseHeaders": "{\"Content-Type\": \"text/plain\"}",
  "responseBody": "File content...",
  "isBase64": false
}
```

---

### Remote Device Browsing

Browse files on connected devices using console commands:

| Command | Description |
|---------|-------------|
| `ls <callsign>` | Enter device context, list collections |
| `ls` | List current directory |
| `cd <path>` | Change directory |
| `cd ..` | Go up one level |
| `pwd` | Show current path |
| `cat <file>` | Display file content |
| `head <file>` | Display first 10 lines |
| `tail <file>` | Display last 10 lines |
| `exit` | Exit device context |

---

### Relay-to-Relay Messages

#### RELAY_HELLO / RELAY_HELLO_ACK
Node relay connects to root relay.

**Hello:**
```json
{
  "type": "RELAY_HELLO",
  "relayCallsign": "X3NODE01",
  "relayNpub": "npub1...",
  "relayType": "node",
  "networkId": "mynetwork"
}
```

**Ack:**
```json
{
  "type": "RELAY_HELLO_ACK",
  "accepted": true,
  "assignedId": "node-X3NODE01-1705320000"
}
```

---

### Update Notifications

#### UPDATE (Relay -> Client)
Notification when content is updated.

**Format:** `UPDATE:{callsign}:{collectionType}:{path}`

**Example:** `UPDATE:X1USER01:blog:/updates`

---

## Network Discovery

Desktop can discover devices on the local network:

1. Scans local IP ranges
2. Checks ports: 80, 8080, 8081, 45678, 3000, 5000
3. Sends HTTP requests to detect Geogram services

**Detection Endpoints:**
- `GET /api/status`
- `GET /relay/status`
- `GET /`

---

## Security

### Protected Paths

These paths are blocked from API access:
- `extra/` directory
- `security.json`, `security.txt`, `.security`
- `.git`, `.gitignore`
- Hidden files (starting with `.`)

### Collection Visibility

| Visibility | API Access | Description |
|------------|------------|-------------|
| `public` | Allowed | Anyone can access |
| `restricted` | Allowed | Shared with authentication |
| `private` | Blocked | Not shared via API |

Configured in `{collection}/extra/security.json`:
```json
{
  "visibility": "public"
}
```

### NOSTR Authentication

- Hello handshakes signed with BIP-340 Schnorr signatures
- Chat messages include NOSTR event signatures
- Signatures verified server-side before acceptance
- Callsigns derived from verified public keys (prevents spoofing)

---

## Error Handling

All errors return JSON with an `error` field:

```json
{
  "error": "Description of the error"
}
```

**HTTP Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Server Error |
| 503 | Service Unavailable |

---

## Configuration

### Relay Server

| Setting | Description | Default |
|---------|-------------|---------|
| `httpPort` | Main server port | 8080 |
| `httpsPort` | HTTPS port (if SSL enabled) | 8443 |
| `adminPort` | Admin dashboard port | 8081 |
| `name` | Relay display name | (callsign) |
| `description` | Relay description | - |
| `maxConnectedDevices` | Max device connections | 1000 |
| `httpRequestTimeout` | Proxy timeout (ms) | 30000 |
| `enableCors` | Enable CORS headers | true |
| `enableSsl` | Enable SSL/TLS | false |
| `tileServerEnabled` | Enable tile endpoint | true |
| `maxCacheSizeMB` | Tile cache size | 500 |

### Desktop Client

| Setting | Default | Description |
|---------|---------|-------------|
| API Port | 45678 | Local HTTP server port |
| Ping Interval | 60s | WebSocket keep-alive |
| Reconnect Interval | 10s | Auto-reconnect delay |

---

## Examples

### Fetch Chat Rooms (HTTP)

```bash
# Get relay's chat rooms
curl "http://relay.example.com:8080/X3RELAY1/api/chat/rooms"
```

### Post Chat Message (HTTP)

```bash
curl -X POST "http://relay.example.com:8080/X3RELAY1/api/chat/rooms/general/messages" \
  -H "Content-Type: application/json" \
  -d '{
    "callsign": "X1USER01",
    "content": "Hello!",
    "npub": "npub1...",
    "pubkey": "hex_pubkey",
    "event_id": "event_id",
    "signature": "sig",
    "created_at": 1705320000
  }'
```

### Connect to Relay (Dart)

```dart
final wsService = WebSocketService();
final success = await wsService.connectAndHello('ws://relay.example.com:8080');

if (success) {
  print('Connected to relay!');
}
```

### Post Chat via WebSocket (Dart)

```dart
final event = NostrEvent.textNote(
  pubkeyHex: pubkey,
  content: 'Hello!',
  tags: [['t', 'chat'], ['room', 'general'], ['callsign', 'X1USER01']],
);
event.calculateId();
event.signWithNsec(nsec);

wsService.send({'nostr_event': ['EVENT', event.toJson()]});
```

### Browse Desktop Files (HTTP)

```bash
curl "http://localhost:45678/files"
curl "http://localhost:45678/files?path=documents"
curl "http://localhost:45678/files/content?path=documents/readme.txt"
```

### Search via Relay (HTTP)

```bash
curl "http://relay.example.com:8080/search?q=document&limit=10"
```

### Get Relay Status (HTTP)

```bash
curl "http://relay.example.com:8080/api/status"
```
