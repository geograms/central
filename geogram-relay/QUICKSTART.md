# Geogram Relay Server - Quick Start Guide

## Installation

### Prerequisites
- Java 21 or higher
- Maven 3.6+ (for building from source)

### Option 1: Download Pre-built JAR
Download `geogram-relay-1.0.0.jar` from releases.

### Option 2: Build from Source
```bash
mvn clean package
```

The JAR will be in `target/geogram-relay-1.0.0.jar` (5.9 MB).

## First Run

```bash
java -jar geogram-relay-1.0.0.jar
```

This will:
1. Create `config.json` with default settings
2. Start server on port 45679
3. Listen for WebSocket device connections
4. Serve HTTP API

## Configuration

On first run, a `config.json` file is created in the current directory:

```json
{
  "port": 45679,
  "host": "0.0.0.0",
  "enableLogging": true,
  "httpRequestTimeout": 30,
  "idleDeviceTimeout": 300,
  "cleanupInterval": 300,
  "maxConnectedDevices": 1000,
  "maxPendingRequests": 10000,
  "callsignPattern": "^[A-Za-z0-9]{3,10}(-[A-Za-z0-9]{1,3})?$",
  "enableCors": false,
  "corsAllowedOrigins": "*",
  "enableRateLimiting": false,
  "maxRequestsPerMinute": 60
}
```

### Common Configuration Changes

**Change Port:**
```json
{
  "port": 8080
}
```

**Enable CORS for Web Apps:**
```json
{
  "enableCors": true,
  "corsAllowedOrigins": "*"
}
```

**Increase Timeouts:**
```json
{
  "httpRequestTimeout": 60,
  "idleDeviceTimeout": 600
}
```

**Limit Connections:**
```json
{
  "maxConnectedDevices": 100,
  "maxPendingRequests": 1000
}
```

After editing `config.json`, restart the server.

## Running the Server

### Default Port (from config.json)
```bash
java -jar geogram-relay-1.0.0.jar
```

### Custom Port (override config)
```bash
java -jar geogram-relay-1.0.0.jar 8080
```

### Using Run Script
```bash
./run-relay.sh [port]
```

### Background Mode
```bash
nohup java -jar geogram-relay-1.0.0.jar > relay.log 2>&1 &
```

### With Systemd (Linux)
Create `/etc/systemd/system/geogram-relay.service`:
```ini
[Unit]
Description=Geogram Relay Server
After=network.target

[Service]
Type=simple
User=geogram
WorkingDirectory=/opt/geogram-relay
ExecStart=/usr/bin/java -jar /opt/geogram-relay/geogram-relay-1.0.0.jar
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable geogram-relay
sudo systemctl start geogram-relay
```

## Testing

### Check Server Status
```bash
curl http://localhost:45679/
```

Response:
```json
{
  "service": "Geogram Relay Server",
  "version": "1.0.0",
  "port": 45679,
  "connected_devices": 0,
  "max_devices": 1000,
  "uptime_seconds": 120
}
```

### List Connected Devices
```bash
curl http://localhost:45679/relay/status
```

### Check Device Info
```bash
curl http://localhost:45679/device/MYDEVICE
```

### Run Test Suite
```bash
./test-relay.sh
```

## Device Connection

Devices connect via WebSocket and register with their callsign:

```javascript
const ws = new WebSocket('ws://localhost:45679/');

ws.onopen = () => {
  ws.send(JSON.stringify({
    type: 'REGISTER',
    callsign: 'DEVICE1'
  }));
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);

  if (msg.type === 'REGISTER') {
    console.log('Registered:', msg.callsign);
  } else if (msg.type === 'HTTP_REQUEST') {
    // Handle HTTP request from relay
    handleRequest(msg);
  }
};
```

## HTTP Proxying

Once a device is connected, you can send HTTP requests through the relay:

```bash
# Request goes: Client -> Relay -> Device -> Relay -> Client
curl http://localhost:45679/device/DEVICE1/api/messages
```

The relay:
1. Receives HTTP request
2. Forwards to device via WebSocket
3. Waits for device response
4. Returns response to HTTP client

## Monitoring

### Server Logs
Logs are printed to stdout/stderr. Redirect to file:
```bash
java -jar geogram-relay-1.0.0.jar > relay.log 2>&1
```

### Health Check
```bash
curl -f http://localhost:45679/ || echo "Server down"
```

### Connected Devices
```bash
curl -s http://localhost:45679/relay/status | jq '.connected_devices'
```

## Troubleshooting

### Port Already in Use
```
Address already in use
```
**Solution:** Change port in `config.json` or use command-line override.

### Config Not Loading
**Check:** `config.json` must be in the working directory where you run the JAR.

### CORS Errors
**Solution:** Enable CORS in `config.json`:
```json
{
  "enableCors": true,
  "corsAllowedOrigins": "*"
}
```

### Device Won't Connect
**Check:**
1. Correct WebSocket URL: `ws://host:port/`
2. Valid callsign format (3-10 alphanumeric chars)
3. Server not at max device limit

### Request Timeout
**Solution:** Increase timeout in `config.json`:
```json
{
  "httpRequestTimeout": 60
}
```

## Security Notes

⚠️ **This is a development/testing relay server. For production:**

1. **Add TLS/SSL** - Use reverse proxy (nginx, Apache)
2. **Add Authentication** - Implement token-based auth
3. **Restrict CORS** - Don't use `"*"` in production
4. **Use Firewall** - Limit access to trusted networks
5. **Monitor Logs** - Set up log aggregation
6. **Rate Limiting** - Implement rate limits (placeholder in config)

## Support

- Documentation: [README.md](README.md)
- Protocol Spec: `../docs/relay/relay-protocol.md`
- Issues: Report bugs in project repository

## Quick Reference

| Task | Command |
|------|---------|
| Start server | `java -jar geogram-relay-1.0.0.jar` |
| Custom port | `java -jar geogram-relay-1.0.0.jar 8080` |
| Check status | `curl http://localhost:45679/` |
| List devices | `curl http://localhost:45679/relay/status` |
| Test suite | `./test-relay.sh` |
| Build | `mvn clean package` |

## Example Use Cases

### 1. Development/Testing
```bash
java -jar geogram-relay-1.0.0.jar
# Access Android devices from web dashboard
```

### 2. Remote Access
```bash
# Run on server with public IP
java -jar geogram-relay-1.0.0.jar
# Devices connect from anywhere
# Access via HTTP API
```

### 3. Load Balancing
```bash
# Multiple relay servers
# config.json on each:
{"port": 45679, "maxConnectedDevices": 500}
{"port": 45680, "maxConnectedDevices": 500}
```

---

**License**: Apache-2.0
**Version**: 1.0.0
