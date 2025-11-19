# Geogram Relay Server

A WebSocket/HTTP relay server for the Geogram mesh messaging system. This relay server enables remote access to Android devices running Geogram, allowing HTTP requests to be proxied through WebSocket connections.

## Overview

The Geogram Relay Server acts as a bridge between HTTP clients and Geogram devices connected via WebSocket. Devices register with the relay using their callsign, and HTTP requests can be proxied to them through the relay.

## Architecture

```
┌─────────────┐         WebSocket          ┌─────────────┐
│   Geogram   │◄──────────────────────────►│    Relay    │
│   Device    │    (Device Registration)   │   Server    │
│  (Android)  │                             │   (Java)    │
└─────────────┘                             └─────────────┘
                                                    ▲
                                                    │ HTTP
                                                    │
                                            ┌───────┴────────┐
                                            │  HTTP Clients  │
                                            │ (Web, Mobile)  │
                                            └────────────────┘
```

## Features

- **WebSocket Device Registration**: Devices connect and register using their callsign
- **HTTP Request Proxying**: Forward HTTP requests to connected devices
- **Multiple HTTP Methods**: Support for GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
- **SSL/TLS Support**: Secure WebSocket (WSS) and HTTPS connections
- **APRS-IS Integration**: Periodic announcements of relay availability to APRS-IS network
- **Automatic Relay Discovery**: Listen for and discover other Geogram relays via APRS-IS
- **Device Management**: Track connected devices, uptime, and idle time
- **Automatic Cleanup**: Remove idle devices after timeout
- **PING/PONG**: Keep-alive mechanism for device connections
- **Flexible Port Configuration**: Default 8080 for local testing, 80 for production

## Protocol

### WebSocket Messages

The relay uses JSON messages over WebSocket:

#### REGISTER (Device → Relay)
```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

#### REGISTER Response (Relay → Device)
```json
{
  "type": "REGISTER",
  "callsign": "DEVICE1"
}
```

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

#### HTTP_REQUEST (Relay → Device)
```json
{
  "type": "HTTP_REQUEST",
  "requestId": "uuid",
  "method": "GET",
  "path": "/api/messages",
  "headers": "{\"Content-Type\":\"application/json\"}",
  "body": ""
}
```

#### HTTP_RESPONSE (Device → Relay)
```json
{
  "type": "HTTP_RESPONSE",
  "requestId": "uuid",
  "statusCode": 200,
  "responseHeaders": "{\"Content-Type\":\"application/json\"}",
  "responseBody": "{\"messages\":[]}"
}
```

#### ERROR (Relay → Device)
```json
{
  "type": "ERROR",
  "error": "Error message"
}
```

## HTTP Endpoints

### GET /
Get relay server information.

**Response:**
```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "websocket_port": 45679,
  "connected_devices": 2
}
```

### GET /relay/status
List all connected devices.

**Response:**
```json
{
  "connected_devices": 2,
  "devices": [
    {
      "callsign": "DEVICE1",
      "uptime_seconds": 3600,
      "idle_seconds": 10,
      "connected_at": 1699564800000
    }
  ]
}
```

### GET /device/{callsign}
Get information about a specific device.

**Response (device connected):**
```json
{
  "callsign": "DEVICE1",
  "connected": true,
  "uptime": 3600,
  "idleTime": 10
}
```

**Response (device not connected):**
```json
{
  "callsign": "DEVICE1",
  "connected": false,
  "error": "Device not connected"
}
```

### ANY /device/{callsign}/*
Proxy HTTP request to device.

All HTTP methods (GET, POST, PUT, DELETE, etc.) are supported. The request is forwarded to the device via WebSocket, and the response is returned to the client.

**Example:**
```bash
curl http://localhost:45679/device/DEVICE1/api/messages
```

This sends an HTTP_REQUEST message to DEVICE1 with:
- method: "GET"
- path: "/api/messages"

The device responds with HTTP_RESPONSE, which is returned to the client.

## Building

### Requirements
- Java 21 or higher
- Maven 3.6+

### Build JAR
```bash
mvn clean package
```

This creates `target/geogram-relay-1.0.0.jar` - a fat JAR with all dependencies included.

## Running

### Start Server
```bash
java -jar target/geogram-relay-1.0.0.jar [port]
```

Default port: 8080 (local testing) or 80 (production)

### Examples
```bash
# Use default port (8080)
java -jar target/geogram-relay-1.0.0.jar

# Use custom port
java -jar target/geogram-relay-1.0.0.jar 80
```

### SSL/TLS Configuration (WSS/HTTPS)

For secure connections, the relay uses **self-signed certificates** that are generated and distributed by the relay itself. This is necessary because the relay may operate in offline environments without internet access.

#### 1. Generate a Self-Signed Certificate

Use the provided script to generate a keystore with a self-signed certificate:

```bash
./generate-keystore.sh
```

This will create a `keystore.jks` file in the current directory. The script will prompt you for:
- Hostname or IP address (default: localhost)

The generated certificate includes:
- 2048-bit RSA key
- 365-day validity
- Subject Alternative Names (SAN) for localhost and 127.0.0.1

#### 2. Enable SSL in Configuration

Edit `config.json` to enable SSL:

```json
{
  "port": 443,
  "enableSsl": true,
  "keystorePath": "keystore.jks",
  "keystorePassword": "changeit",
  "keyPassword": null
}
```

**Important**: Change the default password for production deployments!

#### 3. Start Server with SSL

```bash
java -jar target/geogram-relay-1.0.0.jar
```

The server will now be accessible via:
- WebSocket: `wss://localhost:443/`
- HTTPS: `https://localhost:443/relay/status`

#### 4. Client Certificate Trust

Since the certificate is self-signed, clients need to trust it:

**Android/Java clients:**
```java
// Add the relay's certificate to your truststore
// Or disable certificate validation for this specific host (development only)
```

**Web browsers:**
- Visit `https://localhost:443/` and accept the security warning
- Add the certificate to your browser's trusted certificates

**curl:**
```bash
# Skip certificate verification (development only)
curl -k https://localhost:443/relay/status

# Or specify the certificate
curl --cacert relay-cert.pem https://localhost:443/relay/status
```

#### 5. Export Certificate for Distribution

To distribute the relay's certificate to clients:

```bash
# Export certificate from keystore
keytool -exportcert -alias geogram-relay -keystore keystore.jks \
    -storepass changeit -file relay-cert.der

# Convert to PEM format (optional)
openssl x509 -inform der -in relay-cert.der -out relay-cert.pem
```

Clients can then import this certificate into their truststore.

### APRS-IS Integration

The relay can announce its availability to the APRS-IS (Automatic Packet Reporting System - Internet Service) network. This allows ham radio operators and other systems to discover relay locations.

#### Enabling APRS Announcements

Edit `config.json`:

```json
{
  "enableAprs": true,
  "aprsCallsign": "X3A7B2",
  "aprsServer": "rotate.aprs2.net",
  "aprsPort": 14580,
  "aprsAnnouncementIntervalMinutes": 5,
  "aprsMessage": "Portugal relay",
  "relayUrl": "wss://178.202.105.29:8080"
}
```

**Notes**:
- The `aprsCallsign` is **automatically generated** on first run with an **X3** prefix (indicating relay). Each relay gets a unique 6-character callsign in format `X3XXXX` where X's are random alphanumeric characters.
- The `aprsMessage` can be customized to identify your relay (e.g., "Portugal relay", "Berlin emergency relay", "East Coast Hub"). Maximum length is **200 characters**. The relay will refuse to start if the message exceeds this limit.
- The `relayUrl` is **automatically generated** from the relay's public IP and port. This URL is included in APRS announcements (with " - " divisor) so other relays can discover and connect to this relay. You can manually override it if needed (e.g., if using port forwarding or a domain name). Supports ws://, wss://, http://, and https:// protocols.

The relay will only announce when:
1. APRS is enabled in configuration
2. A valid callsign is configured
3. The relay has a **public IP address** (not 10.x, 172.16-31.x, 192.168.x, 127.x)
4. The relay can reach the APRS-IS server

#### APRS Message Format

The relay uses **standard APRS position beacon format** as defined in the APRS specification:

```
CALLSIGN>APRS,TCPIP*:!/####LLLLLLLL$MESSAGE - URL
```

Example:
```
X3QPSF>APRS,TCPIP*:!/####5CUxP^<Z$Portugal relay - wss://178.202.105.29:8080
```

Format breakdown:
- `X3QPSF` = Auto-generated relay callsign (X3 prefix identifies relays)
- `APRS` = Standard APRS destination
- `TCPIP*` = Message sent via internet
- `!` = Real-time position (no timestamp)
- `/` = Primary symbol table
- `####` = Symbol overlay (digipeater/relay)
- `5CUxP^<Z` = Compressed coordinates in Base91 (8 characters: 4 lat + 4 lon)
- `$` = No course/speed/altitude data
- `Portugal relay` = Custom message from config (configurable via `aprsMessage`)
- ` - ` = Divisor between description and URL
- `wss://178.202.105.29:8080` = Relay URL (auto-generated from public IP + port, can be ws://, wss://, http://, or https://)

#### Coordinate Encoding

Coordinates are encoded using APRS compressed position format (Base91):
- **Precision**: ~0.3m for latitude, ~0.6m for longitude
- **Format**: 8 characters (4 for latitude + 4 for longitude, no separator)
- **Example**: `5CUxP^<Z` represents Bensheim, Germany (49.683°N, 8.622°E)

#### Announcement Frequency

- **Default**: Every 5 minutes
- **Minimum**: 1 minute (configurable via `aprsAnnouncementIntervalMinutes`)
- **Recommended**: 5-30 minutes to avoid network congestion

#### APRS Passcode

The relay automatically calculates the correct APRS-IS passcode for your callsign using the standard algorithm. No manual passcode configuration is required.

#### Monitoring Announcements

You can monitor your relay's APRS announcements using:
- [aprs.fi](https://aprs.fi) - Web-based APRS viewer
- APRS clients (Xastir, YAAC, APRSdroid, etc.)
- `telnet rotate.aprs2.net 14580` - Direct APRS-IS connection

#### Relay Discovery via APRS

The relay automatically discovers other Geogram relays by listening to APRS-IS for X3* announcements:

**How it works**:
1. Relay connects to APRS-IS with filter `p/X3` (receive announcements FROM X3* callsigns)
2. Listens for position beacons from other relays
3. Parses beacon to extract:
   - Callsign (e.g., X3QPSF)
   - Geographic coordinates (latitude/longitude)
   - Relay URL (e.g., http://178.202.105.29:8080)
4. Maintains list of discovered relays in memory
5. Updates last-seen timestamp when relay announces again

**Message Format for Discovery**:
```
X3XXXX>APRS,TCPIP*:!/####LLLLLLLL$Description - protocol://relay-ip:port
```

Example:
```
X3ABCD>APRS,TCPIP*:!/####5CUxP^<Z$Portugal relay - wss://178.202.105.29:8080
```

The relay URL is automatically included in announcements when:
- The relay has a public IP address
- `relayUrl` is configured (auto-generated from IP + port if not set)
- Format uses " - " as divisor between description and URL
- Supports ws://, wss://, http://, and https:// protocols

**Discovered Relay Information**:
- Callsign (X3XXXX format)
- Location (latitude/longitude in decimal degrees)
- URL (HTTP/HTTPS endpoint for relay access)
- Discovery timestamp
- Last seen timestamp
- Age (seconds since last announcement)

This enables automatic relay network formation - relays can discover each other without manual configuration, building a distributed mesh of Geogram relay servers worldwide.

## Testing

### HTTP Tests
Run the HTTP endpoint tests:
```bash
./test-relay.sh
```

### Manual Testing

1. Start the server:
```bash
java -jar target/geogram-relay-1.0.0.jar
```

2. Check server status:
```bash
curl http://localhost:45679/
curl http://localhost:45679/relay/status
```

3. Connect a device via WebSocket and register:
```json
{"type": "REGISTER", "callsign": "TEST1"}
```

4. Send HTTP request to device:
```bash
curl http://localhost:45679/device/TEST1/api/test
```

## Configuration

The relay server uses a `config.json` file for all settings. This file is created automatically in the working directory (where you run the JAR) if it doesn't exist.

### Configuration File: config.json

```json
{
  "port": 8080,
  "host": "0.0.0.0",
  "enableLogging": true,
  "enableSsl": false,
  "keystorePath": "keystore.jks",
  "keystorePassword": "changeit",
  "keyPassword": null,
  "httpRequestTimeout": 30,
  "idleDeviceTimeout": 300,
  "cleanupInterval": 300,
  "maxConnectedDevices": 1000,
  "maxPendingRequests": 10000,
  "callsignPattern": "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$",
  "enableCors": false,
  "corsAllowedOrigins": "*",
  "enableRateLimiting": false,
  "maxRequestsPerMinute": 60,
  "enableAprs": true,
  "aprsCallsign": "",
  "aprsServer": "rotate.aprs2.net",
  "aprsPort": 14580,
  "aprsAnnouncementIntervalMinutes": 5,
  "aprsMessage": "Geogram Relay"
}
```

### Configuration Options

#### Server Settings
- **port** (default: 8080): Server port number (8080 for local, 80 for production)
- **host** (default: "0.0.0.0"): Server bind address
- **enableLogging** (default: true): Enable/disable logging

#### SSL/TLS Settings
- **enableSsl** (default: false): Enable HTTPS/WSS connections
- **keystorePath** (default: "keystore.jks"): Path to Java keystore file
- **keystorePassword** (default: "changeit"): Keystore password
- **keyPassword** (default: null): Key password (uses keystorePassword if null)

#### APRS-IS Settings
- **enableAprs** (default: true): Enable/disable APRS-IS announcements
- **aprsCallsign** (auto-generated): Relay callsign with X3 prefix (e.g., "X3A7B2")
- **aprsServer** (default: "rotate.aprs2.net"): APRS-IS server hostname
- **aprsPort** (default: 14580): APRS-IS server port
- **aprsAnnouncementIntervalMinutes** (default: 5): Minutes between announcements
- **aprsMessage** (default: "Geogram Relay"): Custom message for APRS beacons (max 200 characters)

#### Timeout Settings (in seconds)
- **httpRequestTimeout** (default: 30): Maximum time to wait for device response
- **idleDeviceTimeout** (default: 300): Disconnect idle devices after this time
- **cleanupInterval** (default: 300): Periodic cleanup interval

#### Connection Limits
- **maxConnectedDevices** (default: 1000): Maximum simultaneous device connections
- **maxPendingRequests** (default: 10000): Maximum pending HTTP requests

#### Callsign Validation
- **callsignPattern** (default: `^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$`): Regex pattern for callsign validation

Valid callsigns:
- `DEVICE1`, `TEST`, `STATION-A`, `N0CALL-1`

Invalid callsigns:
- `AB` (too short), `X` (too short), `DEVICE_1` (underscore not allowed)

#### CORS Settings
- **enableCors** (default: false): Enable Cross-Origin Resource Sharing
- **corsAllowedOrigins** (default: "*"): Allowed origins (comma-separated or "*" for all)

Example CORS configurations:
```json
"enableCors": true,
"corsAllowedOrigins": "*"
```

```json
"enableCors": true,
"corsAllowedOrigins": "http://localhost:3000,https://example.com"
```

#### Rate Limiting (not yet implemented)
- **enableRateLimiting** (default: false): Enable rate limiting
- **maxRequestsPerMinute** (default: 60): Maximum requests per minute per device

### Modifying Configuration

1. Edit `config.json` in the directory where you run the JAR
2. Restart the server for changes to take effect
3. Command-line port argument overrides config file:
   ```bash
   java -jar geogram-relay-1.0.0.jar 8080
   ```

### Configuration Validation

The server validates all configuration values on startup:
- Port must be 1-65535
- All timeout values must be >= 1
- All limit values must be >= 1

Invalid configuration will cause the server to exit with an error message.

## Logging

The relay server includes automatic log file management with weekly rotation and cleanup:

### Log Files

- **Location**: `logs/` directory
- **Format**: `log-YY-WW.txt` (e.g., `log-25-47.txt` for week 47 of 2025)
- **Rotation**: Automatically creates new log file each week (~52 files per year)
- **Content**: Timestamped events including:
  - Server startup/shutdown
  - Device connections/disconnections
  - Configuration changes
  - Important operational events

### Automatic Cleanup

**Daily Cleanup Task**:
- Runs every 24 hours
- Removes log files older than 1 year (365 days)
- Based on file modification time

**Size Management**:
- Maximum log file size: 100 MB
- When exceeded: automatically prunes to keep newest 50% of entries
- Hourly size checks via background thread
- Older entries are deleted, newer entries preserved

### Example Log Output

```
[2025-11-19 09:35:20.215] Geogram Relay Server starting...
[2025-11-19 09:35:20.495] Server started on 0.0.0.0:8080
[2025-11-19 09:35:20.495] Location: Bensheim, Germany
[2025-11-19 09:35:20.495] APRS: enabled (callsign: X3QPSF)
[2025-11-19 09:36:15.320] DEVICE_CONNECT: TEST1 from /192.168.1.100:54321
[2025-11-19 10:15:42.103] DEVICE_DISCONNECT: TEST1 (uptime: 2367s)
```

## Components

### Config.java
Configuration management. Loads settings from `config.json`, provides validation, and creates default configuration if needed.

### GeogramRelay.java
Main entry point. Loads configuration, sets up Javalin server with WebSocket and HTTP endpoints.

### RelayServer.java
Manages WebSocket connections, device registration, and request routing. Uses configuration for all operational parameters.

### RelayMessage.java
Data model for relay protocol messages. Handles JSON serialization/deserialization.

### DeviceConnection.java
Represents a connected device with metadata (callsign, connection time, activity tracking).

### PendingRequest.java
Tracks HTTP requests awaiting device response. Uses CompletableFuture for async handling.

### LogManager.java
Manages log files with automatic rotation, size management, and cleanup. Features:
- Weekly log file rotation (log-YY-WW.txt format)
- Automatic pruning when files exceed 100 MB
- Daily cleanup of files older than 1 year
- Background threads for maintenance tasks

## Dependencies

- **Javalin 6.1.3**: HTTP server and WebSocket support
- **Gson 2.10.1**: JSON serialization
- **SLF4J 2.0.9**: Logging

## Use Cases

1. **Remote Device Management**: Access Geogram devices from the internet
2. **Web Dashboard**: Build web interfaces for Geogram mesh networks
3. **API Integration**: Integrate Geogram with external services
4. **Testing**: Test Android app without physical device access
5. **Monitoring**: Centralized monitoring of mesh network devices

## Security Considerations

This is a basic relay implementation. For production use, consider:

- [ ] Add authentication/authorization
- [ ] Implement rate limiting
- [ ] Add TLS/SSL support
- [ ] Validate and sanitize inputs
- [ ] Add CORS configuration
- [ ] Implement access control lists
- [ ] Add request logging and auditing

## License

Apache-2.0

## Related Documentation

- [Android Relay Implementation](../docs/implementation/android-relay-implementation.md)
- [Relay Protocol](../docs/relay/relay-protocol.md)
- [Relay Functionality](../docs/relay/relay-functionality.md)
