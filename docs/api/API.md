# Geogram API Documentation

This document describes the HTTP and WebSocket APIs for the Geogram network. Both **Stations** and **Clients** expose similar APIs, enabling direct peer-to-peer communication. The station acts as a middle path when direct connection is not possible.

## Table of Contents

- [Overview](#overview)
- [Common Concepts](#common-concepts)
  - [Callsigns](#callsigns)
  - [Standard Ports](#standard-ports)
  - [NOSTR Protocol](#nostr-protocol)
  - [Callsign-Scoped API](#callsign-scoped-api)
- [Shared API (Station & Client)](#shared-api-station--client)
  - [Status & Discovery](#status--discovery)
  - [Device List](#device-list)
  - [File Browser](#file-browser)
  - [Chat API](#chat-api)
  - [Blog API](#blog-api)
- [Station-Only API](#station-only-api)
  - [Device Proxy](#device-proxy)
  - [Collections & Search](#collections--search)
  - [Groups API](#groups-api)
  - [Map Tiles](#map-tiles)
  - [SSL/ACME](#sslacme)
  - [CLI API](#cli-api)
  - [Admin Dashboard](#admin-dashboard-api)
- [Client-Only API](#client-only-api)
  - [Log Access](#log-access)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection & Authentication](#connection--authentication)
  - [Device Messages](#device-messages)
  - [Remote Device Browsing](#remote-device-browsing)
  - [Station-to-Station Messages](#station-to-station-messages)
  - [Update Notifications](#update-notifications)
- [Network Discovery](#network-discovery)
- [Connection Types](#connection-types)
- [Security](#security)
- [Error Handling](#error-handling)
- [Configuration](#configuration)
- [Examples](#examples)

---

## Overview

The Geogram network uses a peer-to-peer architecture where **clients communicate directly when possible**, and use **stations as intermediaries** when direct connection is not available.

### Architecture Principle

```
┌─────────┐     Direct (WiFi Local)      ┌─────────┐
│ Client  │◄────────────────────────────►│ Client  │
│ (Phone) │                              │(Desktop)│
└────┬────┘                              └────┬────┘
     │                                        │
     │  Internet                    Internet  │
     │                                        │
     └──────────────►┌─────────┐◄─────────────┘
                     │ Station │
                     │(Server) │
                     └─────────┘
```

### Station (Server)
A server that coordinates device connections and provides shared services:
- **Main Server** (default port 8080): HTTP and WebSocket endpoints
- **Admin Dashboard** (default port 8081): Web administration interface
- Acts as message relay when direct connection is unavailable
- Provides tile caching, search, and other shared services

### Client (Desktop/Mobile)
Applications that serve a local API and connect to stations:
- **Peer Discovery API** (port 3456): Standard port for direct peer discovery
- Connects to stations as a WebSocket client
- **Same API as station** where applicable (status, files, chat, blog)

---

## Common Concepts

### Callsigns

Every device and station in the Geogram network has a unique callsign derived from its NOSTR public key (npub):

| Prefix | Type | Example |
|--------|------|---------|
| `X1` | Desktop/Mobile client | `X1ABC123` |
| `X2` | Reserved | - |
| `X3` | Station server | `X3RELAY1` |

Callsigns are **case-insensitive** in API paths but typically displayed in uppercase.

### Standard Ports

| Port | Purpose | Used By |
|------|---------|---------|
| **3456** | Peer discovery API | All clients (desktop, mobile) |
| **8080** | Main HTTP/WebSocket | Stations |
| **8081** | Admin dashboard | Stations |
| **8443** | HTTPS (if SSL enabled) | Stations |

**Network Discovery** scans these ports in order: `3456, 8080, 80, 8081, 3000, 5000`

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
- Station to store data for connected devices
- Clear ownership of data paths

**Example:**
```
GET /X3RELAY1/api/chat/rooms
GET /X1USER01/api/chat/rooms/general/messages
```

---

## Shared API (Station & Client)

These endpoints are available on **both stations and clients**, enabling direct peer-to-peer communication.

### Status & Discovery

#### GET /
Returns service information and available endpoints.

**Response (Station):**
```json
{
  "service": "Geogram Station Server",
  "version": "1.5.33",
  "status": "online",
  "callsign": "X3ABC123",
  "name": "Downtown Emergency Station",
  "description": "Geogram station for emergency services coordination",
  "connected_devices": 5,
  "location": {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "city": "New York",
    "country": "United States"
  }
}
```

**Response (Client):**
```json
{
  "service": "Geogram Desktop",
  "version": "1.5.33",
  "type": "geogram-desktop",
  "callsign": "X1ABC123",
  "hostname": "my-computer",
  "endpoints": {
    "/api/status": "Device status",
    "/log": "Get log entries",
    "/files": "Browse collections",
    "/files/content": "Get file content"
  }
}
```

---

#### GET /api/status
Returns detailed status information. **Available on both station and client.**

**Response:**
```json
{
  "service": "Geogram Desktop",
  "version": "1.5.33",
  "type": "desktop",
  "status": "online",
  "callsign": "X1ABC123",
  "name": "X1ABC123",
  "hostname": "my-computer",
  "port": 3456
}
```

**Station-specific fields:**
- `started_at` - Server start timestamp
- `uptime_hours` - Server uptime
- `connected_devices` - Number of connected clients
- `max_devices` - Maximum allowed connections
- `chat_rooms` - Number of chat rooms
- `devices` - List of connected devices
- `location` - Disclosed location (city, country, coordinates)

---

### Device List

#### GET /api/devices
List connected devices. On a **station**, lists all connected clients. On a **client**, returns empty or local device info.

**Response:**
```json
{
  "devices": [
    {
      "id": "1765181766832",
      "callsign": "X1PPMG",
      "nickname": "john-desktop",
      "npub": "npub1abc123...",
      "device_type": "desktop",
      "version": "1.5.33",
      "address": "178.202.105.29",
      "latitude": 38.7223,
      "longitude": -9.1393,
      "connection_types": ["internet", "wifi_local"],
      "connected_at": "2024-01-15T11:30:00.832268",
      "last_activity": "2024-01-15T11:35:00.917650"
    }
  ]
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique connection identifier |
| `callsign` | string | Device callsign (e.g., X1PPMG) |
| `nickname` | string? | Optional friendly name |
| `npub` | string? | NOSTR public key (bech32 format) |
| `device_type` | string | Device type: `desktop`, `mobile`, `station` |
| `version` | string? | Client software version |
| `address` | string | Remote IP address |
| `latitude` | number? | Device latitude (if shared) |
| `longitude` | number? | Device longitude (if shared) |
| `connection_types` | string[] | Connection methods (see [Connection Types](#connection-types)) |
| `connected_at` | string | ISO 8601 connection timestamp |
| `last_activity` | string | ISO 8601 last activity timestamp |

---

### File Browser

#### GET /files
Browse collections directory (public collections only). **Available on both station and client.**

**Query Parameters:**
- `path` (optional) - Relative path within collections

**Response (Directory):**
```json
{
  "path": "/documents",
  "base": "/home/user/Documents/geogram/collections",
  "total": 5,
  "entries": [
    {"name": "photos", "type": "directory", "isDirectory": true, "size": 0},
    {"name": "readme.txt", "type": "file", "isDirectory": false, "size": 1024}
  ]
}
```

---

#### GET /files/content
Get file content. **Available on both station and client.**

**Query Parameters:**
- `path` (required) - Relative file path

**Response:** Plain text file content

**Error Responses:**
- `403` - Access denied (private collection or protected path)
- `404` - File not found

---

### Chat API

The Chat API uses **callsign-scoped paths** and is available on **both stations and clients**.

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

**Request Body:**
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

---

#### GET /{callsign}/api/chat/rooms/{roomId}/files
List chat files for offline caching.

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
    }
  ],
  "count": 2
}
```

---

#### GET /{callsign}/api/chat/rooms/{roomId}/file/{year}/{filename}
Get raw chat file content for offline caching.

**Response:** Raw text file preserving NOSTR signatures

---

### Blog API

Blog endpoints are available on **both stations and clients**.

#### GET /{nickname}/blog/{filename}.html
Fetch a rendered HTML blog post.

#### GET /api/blog
List all published blog posts.

#### GET /api/blog/{collection}/{filename}
Get a specific blog post.

**Query Parameters:**
- `format` - Response format: `json` (default), `html`, `markdown`

---

## Station-Only API

These endpoints are only available on **stations**.

### Device Proxy

#### GET /device/{callsign}
Get information about a specific connected device.

**Response (200 - Connected):**
```json
{
  "callsign": "X1USER01",
  "connected": true,
  "uptime": 3600,
  "idleTime": 60
}
```

---

#### ANY /device/{callsign}/*
Proxy HTTP requests to a connected device.

**Example:**
```
GET /device/X1USER01/files
```

The station forwards the request to the device over WebSocket and returns the response.

---

#### GET /{callsign}
#### GET /{callsign}/*
Serve files from a device's `www` collection (website hosting).

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
List all active groups on the station.

#### GET /api/groups/{groupId}
Get detailed information about a specific group.

#### GET /api/groups/{groupId}/members
Get members of a specific group.

**Group Types:**
`association`, `friends`, `authority_police`, `authority_fire`, `authority_civil_protection`, `authority_military`, `health_hospital`, `health_clinic`, `health_emergency`, `admin_townhall`, `admin_regional`, `admin_national`, `infrastructure_utilities`, `infrastructure_transport`, `education_school`, `education_university`, `collection_moderator`

**Member Roles:** `admin`, `moderator`, `contributor`, `guest`

---

### Map Tiles

#### GET /tiles/{callsign}/{z}/{x}/{y}.png
Serve cached map tiles.

**Query Parameters:**
- `layer` (optional) - `standard` (OSM) or `satellite` (Esri)

---

### SSL/ACME

#### GET /.well-known/acme-challenge/{token}
ACME HTTP-01 challenge endpoint for Let's Encrypt certificates.

---

### CLI API

#### POST /api/cli
Execute a CLI command remotely.

---

### Admin Dashboard API

The Admin Dashboard runs on port 8081 and requires authentication.

**Endpoints:**
- `POST /login` - Authenticate
- `GET /logout` - End session
- `GET /api/status` - Station status
- `GET /api/devices` - Connected devices
- `GET /api/rooms` - Chat rooms
- `GET /api/logs?count=50` - Server logs
- `GET /api/config` - Configuration
- `POST /api/kick` - Disconnect device
- `POST /api/ban` - Ban user
- `POST /api/broadcast` - Send message to all
- `POST /api/shutdown` - Shutdown server

---

## Client-Only API

These endpoints are specific to **clients**.

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
  "filter": "station",
  "limit": 50,
  "logs": [
    "[2024-01-15 10:30:00] StationService: Connected to station",
    "..."
  ]
}
```

---

## WebSocket Protocol

### Connection & Authentication

#### hello (Client -> Station)
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

#### hello_ack (Station -> Client)
Response to hello handshake.

**Success:**
```json
{
  "type": "hello_ack",
  "success": true,
  "relay_id": "station-X3RELAY1-1705320000",
  "message": "Welcome X1ABC123"
}
```

---

### Device Messages

#### PING / PONG
Keep-alive heartbeat (every 60 seconds).

#### COLLECTIONS_REQUEST / COLLECTIONS_RESPONSE
Request list of collections from a device.

#### COLLECTION_FILE_REQUEST / COLLECTION_FILE_RESPONSE
Request a specific file from a collection.

#### HTTP_REQUEST / HTTP_RESPONSE
Proxy HTTP requests through WebSocket.

---

### Remote Device Browsing

Console commands for browsing remote devices:

| Command | Description |
|---------|-------------|
| `ls <callsign>` | Enter device context, list collections |
| `ls` | List current directory |
| `cd <path>` | Change directory |
| `cat <file>` | Display file content |
| `exit` | Exit device context |

---

### Station-to-Station Messages

#### RELAY_HELLO / RELAY_HELLO_ACK
Node station connects to root station.

---

### Update Notifications

#### UPDATE (Station -> Client)
Notification when content is updated.

**Format:** `UPDATE:{callsign}:{collectionType}:{path}`

---

## Network Discovery

Geogram discovers devices on the local network using:

1. **Port Scanning**: Scans ports `3456, 8080, 80, 8081, 3000, 5000`
2. **Detection Endpoints**: `GET /api/status`
3. **Service Identification**: Checks response for "Geogram" service type

**Discovery identifies:**
- `station` - Geogram Station Server
- `desktop` - Geogram Desktop Client
- `client` - Generic Geogram client

---

## Connection Types

Devices can have multiple connection methods:

| Type | Tag | Description |
|------|-----|-------------|
| `internet` | Internet | Connected via station over internet |
| `wifi_local` | Wi-Fi Local | Found on same local WiFi network |
| `lan` | LAN | Wired local network connection |
| `bluetooth` | Bluetooth | Bluetooth proximity connection |
| `lora` | LoRa | Long-range radio link |
| `radio` | Radio | General radio connection |
| `esp32mesh` | ESP32 Mesh | ESP32-based mesh network |
| `wifi_halow` | Wi-Fi HaLow | Low-power WiFi (802.11ah) |

**Example:** A device on the same network might show: `["internet", "wifi_local"]`

---

## Security

### Protected Paths

These paths are blocked from API access:
- `extra/` directory (contains security.json)
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
- Signatures verified before acceptance
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

### Station

| Setting | Description | Default |
|---------|-------------|---------|
| `httpPort` | Main server port | 8080 |
| `httpsPort` | HTTPS port (if SSL) | 8443 |
| `adminPort` | Admin dashboard port | 8081 |
| `name` | Station display name | (callsign) |
| `description` | Station description | - |
| `maxConnectedDevices` | Max connections | 1000 |
| `enableSsl` | Enable SSL/TLS | false |
| `tileServerEnabled` | Enable tile endpoint | true |
| `maxCacheSizeMB` | Tile cache size | 500 |

### Client

| Setting | Default | Description |
|---------|---------|-------------|
| Peer Discovery Port | 3456 | Standard discovery port |
| Ping Interval | 60s | WebSocket keep-alive |
| Reconnect Interval | 10s | Auto-reconnect delay |

---

## Examples

### Check Device Status

```bash
# Check client status (direct)
curl "http://192.168.1.100:3456/api/status"

# Check station status
curl "http://station.example.com:8080/api/status"
```

### List Connected Devices

```bash
# From station
curl "http://station.example.com:8080/api/devices"
```

### Browse Files (Direct or via Station)

```bash
# Direct to client on local network
curl "http://192.168.1.100:3456/files"

# Via station proxy
curl "http://station.example.com:8080/device/X1USER01/files"
```

### Get Chat Messages

```bash
# From station
curl "http://station.example.com:8080/X3RELAY1/api/chat/rooms/general/messages"

# Direct from client
curl "http://192.168.1.100:3456/X1USER01/api/chat/rooms/general/messages"
```

### Connect to Station (Dart)

```dart
final wsService = WebSocketService();
final success = await wsService.connectAndHello('ws://station.example.com:8080');

if (success) {
  print('Connected to station!');
}
```

### Search via Station

```bash
curl "http://station.example.com:8080/search?q=document&limit=10"
```
