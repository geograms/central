# Geogram Relay Server API Documentation

Complete API reference for the Geogram Relay Server, including HTTP REST endpoints and WebSocket protocol.

## Table of Contents

- [HTTP REST API](#http-rest-api)
  - [Web Interface](#get-)
  - [Server Status](#get-apistatus)
  - [Legacy Status](#get-status)
  - [Relay Status](#get-relaystatus)
  - [Search Collections](#get-search)
  - [Device Information](#get-devicecallsign)
  - [Device Proxy](#any-devicecallsignpath)
  - [WWW Collection Hosting](#get-callsign)
- [WebSocket Protocol](#websocket-protocol)
  - [Connection](#websocket-connection)
  - [Message Types](#message-types)
  - [Device Registration](#device-registration)
  - [Collections Protocol](#collections-protocol)
  - [Keep-Alive (PING/PONG)](#keep-alive-pingpong)
  - [HTTP Request/Response](#http-requestresponse)
  - [Error Handling](#error-handling)
- [Status Codes](#status-codes)
- [Error Responses](#error-responses)

---

## HTTP REST API

All HTTP endpoints return JSON responses with appropriate HTTP status codes.

### Base URL

```
http://localhost:8080
```

For production deployments with SSL:
```
https://your-relay-server.com
```

---

### GET `/`

Get the relay web interface (HTML).

#### Request

```http
GET / HTTP/1.1
Host: localhost:8080
```

#### Response

**Status:** `200 OK`
**Content-Type:** `text/html`

Returns an interactive HTML web interface with:
- **Search Engine**: Search for files across all connected device collections
- **Server Status**: Real-time server uptime, connected devices count, location
- **Connected Devices List**: Browse devices and access their www collections
- **Auto-refresh**: Status updates every 60 seconds

#### Features

- **Real-time Search**: Searches automatically as you type (4+ characters)
- **Filename Matching**: Search matches filenames only, not full paths
- **Clean Results Display**: Shows filename and collection - device info
- **Device Access**: Click on device callsigns to browse their www collections

#### Example

```bash
# Open in browser
http://localhost:8080/

# Or using curl to get the HTML
curl http://localhost:8080/
```

**Note:** For JSON-formatted server status, use `/api/status` instead.

---

### GET `/api/status`

Get relay server information and health status in JSON format.

#### Request

```http
GET /api/status HTTP/1.1
Host: localhost:8080
```

#### Response

**Status:** `200 OK`

```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "status": "online",
  "started_at": "2025-11-20T14:30:00Z",
  "uptime_hours": 2,
  "port": 8080,
  "description": "Geogram relay server for amateur radio operations",
  "connected_devices": 2,
  "max_devices": 1000,
  "devices": [
    {
      "callsign": "X114CC",
      "uptime_seconds": 3600,
      "idle_seconds": 10,
      "connected_at": "2025-11-20T12:30:00Z"
    }
  ],
  "location": {
    "latitude": 49.683,
    "longitude": 8.6219,
    "city": "Bensheim",
    "region": "Hesse",
    "country": "Germany",
    "country_code": "DE",
    "timezone": "Europe/Berlin",
    "ip": "178.202.105.29",
    "isp": "Vodafone"
  }
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `service` | string | Service name |
| `version` | string | Server version |
| `status` | string | Current status ("online") |
| `started_at` | string | ISO timestamp when server started |
| `uptime_hours` | integer | Server uptime in hours |
| `port` | integer | Server port number |
| `description` | string | Server description (configurable) |
| `connected_devices` | integer | Number of currently connected devices |
| `max_devices` | integer | Maximum allowed devices |
| `devices` | array | Array of connected device objects |
| `devices[].callsign` | string | Device callsign/identifier |
| `devices[].uptime_seconds` | integer | Seconds since device connected |
| `devices[].idle_seconds` | integer | Seconds since last activity |
| `devices[].connected_at` | string | ISO timestamp of connection |
| `location` | object | Server location information |
| `location.latitude` | number | Server latitude |
| `location.longitude` | number | Server longitude |
| `location.city` | string | City name |
| `location.region` | string | Region/state |
| `location.country` | string | Country name |
| `location.country_code` | string | ISO country code |
| `location.timezone` | string | Server timezone |
| `location.ip` | string | Public IP address |
| `location.isp` | string | Internet Service Provider |

#### Example

```bash
curl http://localhost:8080/api/status
```

---

### GET `/status`

Legacy status endpoint for backward compatibility. Returns the same response as `/api/status`.

#### Request

```http
GET /status HTTP/1.1
Host: localhost:8080
```

#### Response

Same as `/api/status`.

**Deprecated:** Use `/api/status` for new implementations.

---

### GET `/relay/status`

List all connected devices with their status information.

#### Request

```http
GET /relay/status HTTP/1.1
Host: localhost:8080
```

#### Response

**Status:** `200 OK`

```json
{
  "connected_devices": 2,
  "devices": [
    {
      "callsign": "DEVICE1",
      "uptime_seconds": 3600,
      "idle_seconds": 10,
      "connected_at": 1699564800000
    },
    {
      "callsign": "DEVICE2",
      "uptime_seconds": 1800,
      "idle_seconds": 5,
      "connected_at": 1699566600000
    }
  ]
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `connected_devices` | integer | Total number of connected devices |
| `devices` | array | Array of device objects |
| `devices[].callsign` | string | Device callsign/identifier |
| `devices[].uptime_seconds` | integer | Seconds since device connected |
| `devices[].idle_seconds` | integer | Seconds since last activity |
| `devices[].connected_at` | long | Connection timestamp (milliseconds since epoch) |

#### Example

```bash
curl http://localhost:8080/relay/status
```

---

### GET `/search`

Search for files across all collections from connected devices.

#### Request

```http
GET /search?q=arduino&limit=50 HTTP/1.1
Host: localhost:8080
```

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `q` | string | Yes | Search query (filename to match) |
| `limit` | integer | No | Maximum results to return (1-500, default: 50) |

#### Response

**Status:** `200 OK`

```json
{
  "query": "arduino",
  "total_results": 3,
  "limit": 50,
  "results": [
    {
      "callsign": "X114CC",
      "collectionName": "electronics",
      "collectionTitle": "Electronics Projects",
      "collectionDescription": "Arduino and Raspberry Pi projects",
      "filePath": "/arduino/led-blink.ino",
      "fileName": "led-blink.ino",
      "fileType": "file",
      "matchType": "file",
      "relevance": 0.9
    },
    {
      "callsign": "X114CC",
      "collectionName": "docs",
      "collectionTitle": "Documentation",
      "collectionDescription": null,
      "filePath": "/tutorials/arduino-basics.pdf",
      "fileName": "arduino-basics.pdf",
      "fileType": "file",
      "matchType": "file",
      "relevance": 0.8
    }
  ]
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `query` | string | Original search query |
| `total_results` | integer | Number of results found |
| `limit` | integer | Maximum results limit applied |
| `results` | array | Array of search result objects |
| `results[].callsign` | string | Device callsign hosting the file |
| `results[].collectionName` | string | Collection directory name |
| `results[].collectionTitle` | string | Human-readable collection title |
| `results[].collectionDescription` | string | Collection description (may be null) |
| `results[].filePath` | string | Full path to file within collection |
| `results[].fileName` | string | Filename only (basename) |
| `results[].fileType` | string | Type of file ("file" or "directory") |
| `results[].matchType` | string | What matched ("file", "collection", or "path") |
| `results[].relevance` | number | Relevance score (0.0 to 1.0, higher = better match) |

#### Search Behavior

- Searches **filenames only**, not full paths (reduces false positives)
- Case-insensitive matching
- Partial matches supported (e.g., "ardu" matches "arduino.txt")
- Results sorted by relevance (exact matches ranked higher)
- Only searches collections cached on the relay server
- Does not search private collections

#### Error Responses

**Missing Query Parameter:**

**Status:** `400 Bad Request`

```json
{
  "error": "Missing query parameter 'q'"
}
```

#### Examples

```bash
# Search for PDF files
curl "http://localhost:8080/search?q=pdf"

# Search for Arduino files with custom limit
curl "http://localhost:8080/search?q=arduino&limit=100"

# Search for images
curl "http://localhost:8080/search?q=.jpg"
```

---

### GET `/{callsign}`

Access the www collection from a connected device. Serves the index.html file.

#### Request

```http
GET /X114CC HTTP/1.1
Host: localhost:8080
```

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `callsign` | string | Device callsign (must match amateur radio callsign pattern) |

#### Response

**Status:** `200 OK`
**Content-Type:** Varies by file (e.g., `text/html`, `image/jpeg`)

Returns the content of the device's www collection index.html file.

#### Error Responses

**Device Not Connected:**

**Status:** `503 Service Unavailable`

```json
{
  "error": "Device not connected",
  "callsign": "X114CC"
}
```

**Invalid Callsign:**

**Status:** `404 Not Found`

```json
{
  "error": "Not found"
}
```

#### Example

```bash
# Access device's www collection
curl http://localhost:8080/X114CC

# Open in browser
http://localhost:8080/X114CC/
```

---

### GET `/{callsign}/{path}`

Access files from a device's www collection.

#### Request

```http
GET /X114CC/images/logo.png HTTP/1.1
Host: localhost:8080
```

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `callsign` | string | Device callsign |
| `path` | string | File path within the www collection |

#### Response

**Status:** `200 OK`
**Content-Type:** Determined by file extension

Returns the requested file content. Supports:
- HTML files (`text/html`)
- CSS files (`text/css`)
- JavaScript files (`application/javascript`)
- Images (PNG, JPEG, GIF, SVG)
- JSON files (`application/json`)
- Text files (`text/plain`)
- Binary files (`application/octet-stream`)

#### File Path Mapping

Request path is mapped to: `/collections/www/{path}`

Example:
- Request: `GET /X114CC/images/logo.png`
- Mapped to: `/collections/www/images/logo.png` on device

#### Error Responses

**File Not Found:**

**Status:** `404 Not Found`

```json
{
  "error": "Not found"
}
```

**Device Not Connected:**

**Status:** `503 Service Unavailable`

```json
{
  "error": "Device not connected",
  "callsign": "X114CC"
}
```

**Request Timeout:**

**Status:** `504 Gateway Timeout`

```json
{
  "error": "Request timeout",
  "callsign": "X114CC",
  "path": "/images/large-file.png"
}
```

#### Examples

```bash
# Get HTML page
curl http://localhost:8080/X114CC/about.html

# Get image
curl http://localhost:8080/X114CC/images/photo.jpg --output photo.jpg

# Get CSS stylesheet
curl http://localhost:8080/X114CC/style.css

# Get JavaScript file
curl http://localhost:8080/X114CC/app.js
```

**See also:** [WWW_COLLECTION_HOSTING.md](WWW_COLLECTION_HOSTING.md) for details on setting up www collections.

---

### GET `/device/{callsign}`

Get information about a specific device.

#### Request

```http
GET /device/DEVICE1 HTTP/1.1
Host: localhost:8080
```

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `callsign` | string | Device callsign (3-10 alphanumeric characters, optional `-` suffix) |

#### Response (Device Connected)

**Status:** `200 OK`

```json
{
  "callsign": "DEVICE1",
  "connected": true,
  "uptime": 3600,
  "idleTime": 10
}
```

#### Response (Device Not Connected)

**Status:** `404 Not Found`

```json
{
  "callsign": "DEVICE1",
  "connected": false,
  "error": "Device not connected"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `callsign` | string | Device callsign |
| `connected` | boolean | Whether device is currently connected |
| `uptime` | integer | Seconds since device connected (if connected) |
| `idleTime` | integer | Seconds since last activity (if connected) |
| `error` | string | Error message (if not connected) |

#### Examples

```bash
# Check if device is connected
curl http://localhost:8080/device/DEVICE1

# Response for connected device
{
  "callsign": "DEVICE1",
  "connected": true,
  "uptime": 3600,
  "idleTime": 10
}

# Response for disconnected device
{
  "callsign": "DEVICE1",
  "connected": false,
  "error": "Device not connected"
}
```

---

### ANY `/device/{callsign}/{path}`

Proxy HTTP request to a connected device.

#### Supported Methods

- `GET`
- `POST`
- `PUT`
- `DELETE`
- `PATCH`
- `HEAD`
- `OPTIONS`

#### Request

```http
GET /device/DEVICE1/api/messages HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer token123
```

#### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `callsign` | string | Target device callsign |
| `path` | string | Path to forward to device (everything after `/device/{callsign}/`) |

#### Request Processing

1. Relay receives HTTP request for `/device/{callsign}/{path}`
2. Relay checks if device is connected
3. Relay forwards request to device via WebSocket (`HTTP_REQUEST` message)
4. Device processes request and responds via WebSocket (`HTTP_RESPONSE` message)
5. Relay returns device response to HTTP client

#### Response

The response depends on what the device returns. The relay forwards:
- Status code
- Headers
- Body

**Example Response:**

**Status:** `200 OK` (or any status code returned by device)

```json
{
  "messages": [
    {
      "id": 1,
      "text": "Hello World",
      "timestamp": 1699564800000
    }
  ]
}
```

#### Error Responses

**Device Not Connected:**

**Status:** `502 Bad Gateway`

```json
{
  "error": "Device not connected"
}
```

**Request Timeout:**

**Status:** `504 Gateway Timeout`

```json
{
  "error": "Request timeout"
}
```

**Invalid Callsign Format:**

**Status:** `400 Bad Request`

```json
{
  "error": "Invalid callsign format"
}
```

#### Examples

**GET Request:**

```bash
curl http://localhost:8080/device/DEVICE1/api/status
```

**POST Request:**

```bash
curl -X POST http://localhost:8080/device/DEVICE1/api/messages \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from relay"}'
```

**PUT Request:**

```bash
curl -X PUT http://localhost:8080/device/DEVICE1/api/config \
  -H "Content-Type: application/json" \
  -d '{"setting": "value"}'
```

**DELETE Request:**

```bash
curl -X DELETE http://localhost:8080/device/DEVICE1/api/messages/123
```

#### Timeout Configuration

The default request timeout is **30 seconds** (configurable via `httpRequestTimeout` in `config.json`). If the device doesn't respond within this time, a `504 Gateway Timeout` is returned.

---

## WebSocket Protocol

The relay uses WebSocket connections for device registration and communication.

### WebSocket Connection

#### Endpoint

```
ws://localhost:8080/
```

For SSL/TLS:
```
wss://your-relay-server.com/
```

#### Connection Example (JavaScript)

```javascript
const ws = new WebSocket('ws://localhost:8080/');

ws.onopen = () => {
  console.log('Connected to relay');

  // Register device
  ws.send(JSON.stringify({
    type: 'REGISTER',
    callsign: 'DEVICE1'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected from relay');
};
```

---

### Message Types

All WebSocket messages are JSON objects with a `type` field.

| Type | Direction | Description |
|------|-----------|-------------|
| `REGISTER` | Device → Relay | Register device with callsign |
| `REGISTER` | Relay → Device | Registration confirmation |
| `PING` | Device → Relay | Keep-alive ping |
| `PONG` | Relay → Device | Keep-alive pong response |
| `HTTP_REQUEST` | Relay → Device | Forward HTTP request to device |
| `HTTP_RESPONSE` | Device → Relay | HTTP response from device |
| `COLLECTIONS_REQUEST` | Relay → Device | Request list of collection names |
| `COLLECTIONS_RESPONSE` | Device → Relay | List of collection names |
| `COLLECTION_FILE_REQUEST` | Relay → Device | Request specific collection file |
| `COLLECTION_FILE_RESPONSE` | Device → Relay | Collection file content |
| `ERROR` | Relay → Device | Error notification |

---

### Device Registration

Devices must register with a callsign before they can receive requests.

#### REGISTER (Device → Relay)

**Request:**

```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Must be `"REGISTER"` |
| `callsign` | string | Yes | Device identifier (3-10 chars, alphanumeric, optional `-` suffix) |

**Callsign Format:**

- **Valid:** `DEVICE1`, `TEST`, `STATION-A`, `N0CALL-1`, `ABC123`
- **Invalid:** `AB` (too short), `X` (too short), `DEVICE_1` (underscore not allowed)

#### REGISTER Response (Relay → Device)

**Success Response:**

```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

**Error Response:**

```json
{
  "type": "ERROR",
  "error": "Invalid callsign format"
}
```

Possible errors:
- `Invalid callsign format` - Callsign doesn't match required pattern
- `Callsign already registered` - Another device is using this callsign
- `Maximum devices reached` - Server has reached connection limit

---

### Collections Protocol

The relay can request collection metadata and files from connected devices for caching and search purposes.

#### COLLECTIONS_REQUEST (Relay → Device)

Request list of collection names from the device.

```json
{
  "type": "COLLECTIONS_REQUEST",
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"COLLECTIONS_REQUEST"` |
| `requestId` | string | Unique request identifier (UUID) |

#### COLLECTIONS_RESPONSE (Device → Relay)

Return list of public/restricted collection names (private collections excluded).

```json
{
  "type": "COLLECTIONS_RESPONSE",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "collections": ["books", "electronics", "www"]
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"COLLECTIONS_RESPONSE"` |
| `requestId` | string | Must match request ID from `COLLECTIONS_REQUEST` |
| `collections` | array | Array of collection name strings |

**Important:** Devices should only return public and restricted collections, not private ones.

#### COLLECTION_FILE_REQUEST (Relay → Device)

Request a specific file from a collection.

```json
{
  "type": "COLLECTION_FILE_REQUEST",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "collectionName": "books",
  "fileName": "collection"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"COLLECTION_FILE_REQUEST"` |
| `requestId` | string | Unique request identifier (UUID) |
| `collectionName` | string | Collection name |
| `fileName` | string | File to retrieve: "collection", "tree", or "data" |

**File Types:**

| fileName | Description | Actual File |
|----------|-------------|-------------|
| `collection` | Collection metadata | `collection.js` |
| `tree` | File tree structure | `extra/tree.json` |
| `data` | TLSH hash data for similarity search | `extra/data.js` |

#### COLLECTION_FILE_RESPONSE (Device → Relay)

Return the requested file content.

```json
{
  "type": "COLLECTION_FILE_RESPONSE",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "collectionName": "books",
  "fileName": "collection.js",
  "fileContent": "window.COLLECTION_DATA = {...}"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"COLLECTION_FILE_RESPONSE"` |
| `requestId` | string | Must match request ID from `COLLECTION_FILE_REQUEST` |
| `collectionName` | string | Collection name |
| `fileName` | string | Actual filename (e.g., "collection.js", "extra/tree.json") |
| `fileContent` | string | Full file content as string |

**Important Notes:**

- File content can be large (up to 10MB for tree.json files)
- WebSocket max message size is configured to 10MB
- Devices should check collection visibility before responding
- If collection is private or doesn't exist, respond with error

---

### Keep-Alive (PING/PONG)

Devices should send periodic PING messages to maintain the connection and reset idle timeout.

#### PING (Device → Relay)

```json
{
  "type": "PING"
}
```

#### PONG (Relay → Device)

```json
{
  "type": "PONG"
}
```

**Recommended Interval:** Every 30-60 seconds

**Idle Timeout:** Devices are disconnected after 300 seconds (5 minutes) of inactivity by default (configurable via `idleDeviceTimeout` in `config.json`).

---

### HTTP Request/Response

When an HTTP request is received for a device, the relay forwards it via WebSocket.

#### HTTP_REQUEST (Relay → Device)

```json
{
  "type": "HTTP_REQUEST",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "method": "GET",
  "path": "/api/messages",
  "headers": "{\"Content-Type\":\"application/json\",\"Authorization\":\"Bearer token123\"}",
  "body": ""
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"HTTP_REQUEST"` |
| `requestId` | string | Unique request identifier (UUID) |
| `method` | string | HTTP method (GET, POST, PUT, DELETE, etc.) |
| `path` | string | Request path (without `/device/{callsign}` prefix) |
| `headers` | string | JSON-encoded HTTP headers object |
| `body` | string | Request body (may be empty) |

#### HTTP_RESPONSE (Device → Relay)

```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "statusCode": 200,
  "responseHeaders": "{\"Content-Type\":\"application/json\"}",
  "responseBody": "{\"messages\":[{\"id\":1,\"text\":\"Hello\"}]}"
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Always `"HTTP_RESPONSE"` |
| `requestId` | string | Must match the request ID from `HTTP_REQUEST` |
| `statusCode` | integer | HTTP status code (200, 404, 500, etc.) |
| `responseHeaders` | string | JSON-encoded HTTP headers object |
| `responseBody` | string | Response body (may be empty) |

**Important:** The device must respond with the same `requestId` it received in the `HTTP_REQUEST`.

---

### Error Handling

#### ERROR (Relay → Device)

```json
{
  "type": "ERROR",
  "error": "Device not registered"
}
```

**Common Errors:**

| Error Message | Description |
|---------------|-------------|
| `Invalid callsign format` | Callsign doesn't match required pattern |
| `Callsign already registered` | Callsign is already in use |
| `Device not registered` | Device tried to send message before registering |
| `Maximum devices reached` | Server connection limit reached |
| `Invalid message format` | Message JSON is malformed |

---

## Status Codes

### HTTP Status Codes

| Code | Message | Description |
|------|---------|-------------|
| `200` | OK | Request successful |
| `400` | Bad Request | Invalid request format or parameters |
| `404` | Not Found | Device or resource not found |
| `502` | Bad Gateway | Device not connected or unavailable |
| `504` | Gateway Timeout | Device didn't respond within timeout period |
| `500` | Internal Server Error | Server error |

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error description"
}
```

### Common Error Scenarios

#### Device Not Connected

**Request:**
```bash
curl http://localhost:8080/device/OFFLINE/api/status
```

**Response:** `502 Bad Gateway`
```json
{
  "error": "Device not connected"
}
```

#### Invalid Callsign Format

**Request:**
```bash
curl http://localhost:8080/device/X/api/status
```

**Response:** `400 Bad Request`
```json
{
  "error": "Invalid callsign format"
}
```

#### Request Timeout

**Request:**
```bash
curl http://localhost:8080/device/SLOW/api/process
```

**Response:** `504 Gateway Timeout`
```json
{
  "error": "Request timeout"
}
```

---

## Configuration

API behavior can be configured via `config.json`:

```json
{
  "httpRequestTimeout": 30,
  "idleDeviceTimeout": 300,
  "maxConnectedDevices": 1000,
  "maxPendingRequests": 10000,
  "callsignPattern": "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$"
}
```

### Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `httpRequestTimeout` | 30 | Seconds to wait for device response |
| `idleDeviceTimeout` | 300 | Seconds before disconnecting idle device |
| `maxConnectedDevices` | 1000 | Maximum simultaneous connections |
| `maxPendingRequests` | 10000 | Maximum pending HTTP requests |
| `callsignPattern` | See above | Regex pattern for callsign validation |

---

## Complete Flow Example

### 1. Device Connects and Registers

**Device → Relay (WebSocket):**
```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

**Relay → Device (WebSocket):**
```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

### 2. Client Sends HTTP Request

**Client → Relay (HTTP):**
```http
GET /device/DEVICE1/api/messages HTTP/1.1
Host: localhost:8080
Authorization: Bearer token123
```

### 3. Relay Forwards to Device

**Relay → Device (WebSocket):**
```json
{
  "type": "HTTP_REQUEST",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "method": "GET",
  "path": "/api/messages",
  "headers": "{\"Authorization\":\"Bearer token123\"}",
  "body": ""
}
```

### 4. Device Processes and Responds

**Device → Relay (WebSocket):**
```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "550e8400-e29b-41d4-a716-446655440000",
  "statusCode": 200,
  "responseHeaders": "{\"Content-Type\":\"application/json\"}",
  "responseBody": "{\"messages\":[{\"id\":1,\"text\":\"Hello\"}]}"
}
```

### 5. Relay Returns to Client

**Relay → Client (HTTP):**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "messages": [
    {
      "id": 1,
      "text": "Hello"
    }
  ]
}
```

---

## Rate Limiting

Rate limiting is planned but not yet implemented. When enabled, it will limit requests per device.

**Configuration:**
```json
{
  "enableRateLimiting": false,
  "maxRequestsPerMinute": 60
}
```

---

## CORS Support

CORS can be enabled for web browser access.

**Configuration:**
```json
{
  "enableCors": true,
  "corsAllowedOrigins": "http://localhost:3000,https://example.com"
}
```

Use `"*"` to allow all origins (not recommended for production).

---

## See Also

- [QUICKSTART.md](QUICKSTART.md) - Getting started guide
- [CONFIG_MIGRATION.md](CONFIG_MIGRATION.md) - Configuration reference
- [NAT_TRAVERSAL.md](NAT_TRAVERSAL.md) - NAT traversal and use cases
- [STATUS_API.md](STATUS_API.md) - Additional status endpoints
