# Geogram Relay Status API

## Overview

The Geogram Relay exposes comprehensive status information through the `/api/status` endpoint, providing details about the relay server, including uptime, location, connected devices, and server description.

## Endpoints

### Primary Endpoint (JSON)

```
GET http://relay-server:port/api/status
```

For local testing:
```
GET http://localhost:8080/api/status
```

### Legacy Endpoint (JSON)

```
GET http://relay-server:port/status
```

**Note:** The `/status` endpoint is maintained for backward compatibility. New applications should use `/api/status`.

### Web Interface (HTML)

```
GET http://relay-server:port/
```

The root endpoint (`/`) now serves an interactive HTML web interface with search functionality and real-time server status. For JSON responses, use `/api/status` instead.

## Response Format

The API returns a JSON object with the following structure:

```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "status": "online",
  "started_at": "2025-11-20T14:30:00.000Z",
  "uptime_hours": 2,
  "port": 8080,
  "description": "Geogram relay server for amateur radio operations",

  "connected_devices": 1,
  "max_devices": 1000,
  "devices": [
    {
      "callsign": "X114CC",
      "uptime_seconds": 7200,
      "idle_seconds": 5,
      "connected_at": "2025-11-20T14:30:00.000Z"
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

## Fields Description

### Server Information
- **service**: Always "Geogram Relay Server"
- **version**: Current version of the relay software
- **status**: Current status (typically "online")
- **started_at**: ISO 8601 timestamp when server started
- **uptime_hours**: Server uptime in hours since start
- **port**: Port the relay is listening on
- **description**: User-configurable server description (set in config.json)

### Device Information
- **connected_devices**: Number of currently connected devices
- **max_devices**: Maximum number of devices that can connect (configurable)
- **devices**: Array of connected device objects, each containing:
  - **callsign**: Amateur radio callsign of the device
  - **uptime_seconds**: Seconds since the device connected
  - **idle_seconds**: Seconds since the device's last activity
  - **connected_at**: ISO 8601 timestamp when device connected

### Location Information
- **latitude**: Server latitude coordinates
- **longitude**: Server longitude coordinates
- **city**: City where server is located
- **region**: Region/state where server is located
- **country**: Country where server is located
- **country_code**: ISO country code (e.g., "DE", "US")
- **timezone**: Server timezone (e.g., "Europe/Berlin")
- **ip**: Public IP address of the server
- **isp**: Internet Service Provider

## Configuration

The server description and location information can be configured in `config.json`:

```json
{
  "serverDescription": "My custom relay description",
  "latitude": 49.683,
  "longitude": 8.6219,
  "city": "Bensheim",
  "region": "Hesse",
  "country": "Germany",
  "countryCode": "DE"
}
```

## Example Usage

### Using curl
```bash
curl http://localhost:8080/api/status
```

### Using wget
```bash
wget -qO- http://localhost:8080/api/status
```

### Using Python
```python
import requests
response = requests.get('http://localhost:8080/api/status')
status = response.json()
print(f"Relay: {status['service']} v{status['version']}")
print(f"Uptime: {status['uptime_hours']} hours")
print(f"Connected devices: {status['connected_devices']}/{status['max_devices']}")
print(f"Location: {status['location']['city']}, {status['location']['country']}")
```

### Using JavaScript/Fetch
```javascript
fetch('http://localhost:8080/api/status')
  .then(response => response.json())
  .then(status => {
    console.log(`Relay: ${status.service} v${status.version}`);
    console.log(`Status: ${status.status}`);
    console.log(`Uptime: ${status.uptime_hours} hours`);
    console.log(`Devices: ${status.connected_devices}/${status.max_devices}`);
    console.log(`Location: ${status.location.city}, ${status.location.country}`);
  });
```

## Use Cases

1. **Service Discovery**: Desktop/mobile apps can query this endpoint to discover relay capabilities and location
2. **Health Monitoring**: Monitor relay uptime and status
3. **Device Management**: See which devices are currently connected
4. **Load Balancing**: Choose relays based on number of connected devices
5. **Geographic Selection**: Select nearest relay based on coordinates
6. **Debugging**: Verify server configuration and connectivity

## Related Endpoints

- `GET /` - Interactive HTML web interface with search and status display
- `GET /status` - Legacy status endpoint (backward compatibility, same as `/api/status`)
- `GET /relay/status` - Minimal endpoint with only device list
- `GET /search?q=<query>` - Search for files across all device collections
- `GET /device/{callsign}` - Check if specific device is connected
- `GET /{callsign}` - Access device's www collection
- `WS /` - WebSocket endpoint for device connections

See [API.md](API.md) for complete API reference.
