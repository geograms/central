# P2P Integration for Collections

This document describes how Collections integrate with Geogram's P2P networking system for remote access and sharing.

## Overview

Collections can be accessed remotely over P2P connections, enabling:
- Browse collections on nearby devices
- Download files on-demand
- Share collections without internet
- Discover collections from peers

## Architecture

### P2P Stack

```
┌─────────────────────────────────┐
│  RemoteCollectionsFragment      │
│  CollectionBrowserFragment      │
│  (Remote Mode)                  │
└─────────────┬───────────────────┘
              │
┌─────────────▼───────────────────┐
│      P2PHttpClient              │
│  HTTP API over P2P transport    │
└─────────────┬───────────────────┘
              │
┌─────────────▼───────────────────┐
│      P2P Transport Layer        │
│  WiFi Direct, Bluetooth, etc.   │
└─────────────────────────────────┘
```

### Remote Access Flow

```
User opens Remote Collections
      ↓
Discover nearby devices
      ↓
For each device:
  ↓
  GET /collections → List of collections
  ↓
  Display in UI
      ↓
User taps collection
      ↓
GET /collections/{npub} → Collection metadata
      ↓
GET /collections/{npub}/files → File tree
      ↓
Display in browser
      ↓
User taps file
      ↓
GET /collections/{npub}/files/{path} → Download file
      ↓
Open file
```

## P2P HTTP API

The Collections system exposes an HTTP API over P2P transports for remote access.

### Base URL

```
http://{device-ip}:8080/
```

Where `{device-ip}` is the P2P connection address (WiFi Direct, local network, etc.)

### Authentication

**Current**: No authentication (trusted local network)
**Future**: Nostr-based authentication using NIP-04 or NIP-26

### Endpoints

#### 1. List Collections

**Request**:
```http
GET /collections HTTP/1.1
Host: {device-ip}:8080
```

**Response**:
```json
{
  "collections": [
    {
      "id": "npub1abc...",
      "title": "My Collection",
      "description": "Description here",
      "files_count": 42,
      "total_size": 1048576,
      "updated": "2025-11-16T12:00:00Z",
      "visibility": "public"
    },
    {
      "id": "npub1def...",
      "title": "Another Collection",
      ...
    }
  ]
}
```

**Notes**:
- Only returns publicly accessible collections
- Or collections user has access to (with auth)
- Respects security.json settings

#### 2. Get Collection Metadata

**Request**:
```http
GET /collections/{npub} HTTP/1.1
Host: {device-ip}:8080
```

**Response**:
```json
{
  "version": "1.0",
  "collection": {
    "id": "npub1abc...",
    "title": "My Collection",
    "description": "Description",
    "created": "2025-11-16T10:00:00Z",
    "updated": "2025-11-16T12:00:00Z",
    "signature": ""
  },
  "statistics": {
    "files_count": 42,
    "folders_count": 5,
    "total_size": 1048576,
    ...
  },
  "views": { ... },
  "tags": ["tag1", "tag2"],
  "metadata": { ... }
}
```

**Errors**:
- `404 Not Found`: Collection doesn't exist
- `403 Forbidden`: User doesn't have access

#### 3. Get File Tree

**Request**:
```http
GET /collections/{npub}/files HTTP/1.1
Host: {device-ip}:8080
```

**Optional Query Parameters**:
- `path={folder}`: Get files in specific folder only
- `recursive=true`: Include subdirectories recursively

**Response**:
```json
{
  "files": [
    {
      "path": "folder/file.txt",
      "name": "file.txt",
      "type": "file",
      "size": 1024,
      "mimeType": "text/plain",
      "hashes": {
        "sha1": "abc123..."
      },
      "metadata": {
        "mime_type": "text/plain"
      }
    },
    {
      "path": "folder",
      "name": "folder",
      "type": "directory"
    }
  ]
}
```

**Errors**:
- `404 Not Found`: Collection doesn't exist
- `403 Forbidden`: User doesn't have access

#### 4. Download File

**Request**:
```http
GET /collections/{npub}/files/{path} HTTP/1.1
Host: {device-ip}:8080
```

**Example**:
```http
GET /collections/npub1abc.../files/folder/document.pdf HTTP/1.1
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Length: 524288
Content-Disposition: attachment; filename="document.pdf"
X-SHA1-Hash: abc123def456...

[Binary file data]
```

**Headers**:
- `Content-Type`: MIME type of file
- `Content-Length`: File size in bytes
- `Content-Disposition`: Suggested filename
- `X-SHA1-Hash`: SHA1 hash for integrity check

**Errors**:
- `404 Not Found`: File doesn't exist
- `403 Forbidden`: User doesn't have access to file
- `416 Range Not Satisfiable`: Invalid byte range

**Partial Downloads** (Future):
```http
GET /collections/{npub}/files/{path} HTTP/1.1
Range: bytes=0-1023
```

Response:
```http
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-1023/524288
...
```

#### 5. Get Collection Torrent (Future)

**Request**:
```http
GET /collections/{npub}/torrent HTTP/1.1
```

**Response**:
```http
HTTP/1.1 200 OK
Content-Type: application/x-bittorrent
Content-Disposition: attachment; filename="collection.torrent"

[Torrent file data]
```

## Client Implementation

### P2PHttpClient

The `P2PHttpClient` class provides a Java API for accessing remote collections.

#### Fetching Collections

```java
// Get list of collections from device
List<Collection> collections = P2PHttpClient.fetchCollections(deviceIp);

for (Collection collection : collections) {
    Log.d(TAG, "Remote collection: " + collection.getTitle());
}
```

#### Fetching Collection Metadata

```java
// Get detailed metadata for specific collection
Collection collection = P2PHttpClient.fetchCollection(deviceIp, npub);
Log.d(TAG, "Collection: " + collection.getTitle());
Log.d(TAG, "Files: " + collection.getFilesCount());
```

#### Fetching File Tree

```java
// Get file list for collection
List<CollectionFile> files = P2PHttpClient.fetchCollectionFiles(deviceIp, npub);

for (CollectionFile file : files) {
    Log.d(TAG, file.getPath() + " - " + file.getFormattedSize());
}
```

#### Downloading Files

```java
// Download file from remote collection
File localFile = P2PHttpClient.downloadFile(deviceIp, npub, filePath);

// Open file
Intent intent = new Intent(Intent.ACTION_VIEW);
Uri uri = FileProvider.getUriForFile(context, authority, localFile);
intent.setDataAndType(uri, mimeType);
startActivity(intent);
```

#### Error Handling

```java
try {
    Collection collection = P2PHttpClient.fetchCollection(deviceIp, npub);
} catch (IOException e) {
    // Network error
    Log.e(TAG, "Failed to fetch collection", e);
} catch (SecurityException e) {
    // Access denied
    Log.e(TAG, "Access denied", e);
} catch (NotFoundException e) {
    // Collection not found
    Log.e(TAG, "Collection not found", e);
}
```

## Device Discovery

### Discovery Mechanisms

Collections leverage existing P2P discovery:

1. **WiFi Direct**: Discover devices on WiFi Direct network
2. **Bluetooth**: Discover devices via Bluetooth scanning
3. **Local Network**: mDNS/DNS-SD for local network discovery
4. **Manual**: Enter IP address manually

### DeviceManager Integration

```java
// Get list of connected devices
List<Device> devices = DeviceManager.getConnectedDevices();

for (Device device : devices) {
    String ip = device.getIpAddress();

    // Fetch collections from each device
    List<Collection> collections = P2PHttpClient.fetchCollections(ip);

    // Display in UI
    displayRemoteCollections(device, collections);
}
```

### RemoteProfileCache

Device information cached for quick access:

```java
// Get device profile
RemoteProfile profile = RemoteProfileCache.getProfile(deviceIp);

String deviceName = profile.getName();
String deviceIcon = profile.getIcon();

// Display in UI with device context
```

## Security Considerations

### Current Security Model

**Trusted Local Network**: Assumes devices on P2P network are trusted

**Risks**:
- No authentication
- No encryption
- Anyone on network can access public collections

**Mitigations**:
- Only expose public collections by default
- Use WiFi Direct for isolated network
- Disable P2P server if not needed

### Future Security Enhancements

#### 1. Nostr-Based Authentication

Use Nostr keys for authentication:

**Challenge-Response Flow**:
```
Client → Server: GET /collections
Server → Client: 401 Unauthorized
                 WWW-Authenticate: Nostr challenge={random}
Client → Server: GET /collections
                 Authorization: Nostr npub={npub} signature={sig}
Server: Verify signature(challenge, npub)
        ↓
Server → Client: 200 OK + Collections
```

**Implementation**:
```java
// Client side
String challenge = parseChallenge(response.getHeader("WWW-Authenticate"));
String signature = NostrSigner.sign(challenge, nsec);
request.addHeader("Authorization", "Nostr npub=" + npub + " signature=" + signature);

// Server side
String challenge = generateChallenge();
sendChallenge(challenge);

String npub = parseAuthHeader(request.getHeader("Authorization"));
String signature = parseSignature(request.getHeader("Authorization"));

if (NostrSigner.verify(challenge, signature, npub)) {
    // Check whitelist
    if (security.getWhitelistedUsers().contains(npub)) {
        // Grant access
    }
}
```

#### 2. TLS Encryption

Use TLS for encrypted communication:

**Certificate Generation**:
```java
// Self-signed cert for P2P
KeyPair keyPair = generateKeyPair();
X509Certificate cert = generateSelfSignedCert(keyPair);

// Use in HTTP server
SSLContext sslContext = SSLContext.getInstance("TLS");
sslContext.init(keyManagerFactory, trustManagerFactory, null);
```

**Trust Model**:
- Trust on first use (TOFU)
- Pin certificates for known devices
- Warn on certificate changes

#### 3. End-to-End Encryption

Encrypt files before transmission:

**Key Exchange**:
```
Client and Server exchange ephemeral keys
  ↓
Derive shared secret using ECDH
  ↓
Use shared secret to encrypt/decrypt files
```

## Performance Optimization

### Caching

**Remote Collections Cache**:
```java
// Cache collection metadata
CollectionCache.put(npub, collection, TTL);

// Fetch from cache
Collection collection = CollectionCache.get(npub);
if (collection == null || collection.isExpired()) {
    collection = P2PHttpClient.fetchCollection(deviceIp, npub);
    CollectionCache.put(npub, collection, TTL);
}
```

**File Cache**:
```java
// Cache downloaded files
File cachedFile = FilCache.get(npub, filePath);
if (cachedFile == null || !cachedFile.exists()) {
    cachedFile = P2PHttpClient.downloadFile(deviceIp, npub, filePath);
    FileCache.put(npub, filePath, cachedFile);
}
```

### Compression

**gzip Compression**:
```http
GET /collections HTTP/1.1
Accept-Encoding: gzip

HTTP/1.1 200 OK
Content-Encoding: gzip
```

**File Compression** (Future):
Compress large files before transmission:
```http
GET /collections/{npub}/files/{path}?compress=true
```

### Resumable Downloads

Support HTTP Range requests for large files:

```http
GET /collections/{npub}/files/{path} HTTP/1.1
Range: bytes=1024-2047

HTTP/1.1 206 Partial Content
Content-Range: bytes 1024-2047/524288
```

Client can resume interrupted downloads.

### Bandwidth Throttling

Limit bandwidth usage:

```java
// Server-side throttling
OutputStream throttledStream = new ThrottledOutputStream(
    outputStream,
    maxBytesPerSecond
);
```

## Integration with BitTorrent

Collections can be distributed via BitTorrent for scalability.

### Torrent Generation

```java
// Generate .torrent file for collection
TorrentGenerator.generate(collection, outputFile);
```

**Torrent Contents**:
- All files in collection
- Collection metadata
- Security configuration
- File hashes

**Trackerless Mode**:
- Use DHT for peer discovery
- No central tracker needed
- Fully decentralized

### Torrent Structure

```
collection_name.torrent
├── announce: (empty for DHT)
├── info:
│   ├── name: "{collection-title}"
│   ├── pieces: [SHA1 pieces]
│   └── files:
│       ├── collection.js
│       ├── extra/security.json
│       ├── extra/tree-data.js
│       └── [all collection files]
```

### Importing from Torrent

```java
// User imports .torrent file
TorrentImporter.importCollection(torrentFile, context);
```

**Process**:
1. Parse .torrent file
2. Extract collection metadata
3. Download files via BitTorrent
4. Verify SHA1 hashes
5. Create collection in app storage

### Hybrid Distribution

Combine P2P HTTP and BitTorrent:
- **Small collections**: P2P HTTP (fast, direct)
- **Large collections**: BitTorrent (scalable, resumable)
- **Popular collections**: BitTorrent (distributed load)

## Testing P2P Access

### Local Testing

Test P2P access without multiple devices:

1. **Emulator + Physical Device**: Connect via local network
2. **Two Physical Devices**: Connect via WiFi Direct
3. **Localhost Loopback**: Test HTTP API locally

```bash
# Start P2P server
adb shell am start -n offgrid.geogram/.MainActivity

# Test API
curl http://localhost:8080/collections
```

### Network Simulation

Simulate network conditions:

```java
// Simulate slow network
P2PHttpClient.setNetworkDelay(500); // 500ms latency

// Simulate bandwidth limit
P2PHttpClient.setBandwidthLimit(100 * 1024); // 100 KB/s

// Simulate packet loss
P2PHttpClient.setPacketLoss(0.05); // 5% packet loss
```

## Troubleshooting

### Connection Issues

**Problem**: Can't connect to remote device

**Solutions**:
1. Check devices are on same network
2. Verify P2P server is running
3. Check firewall settings
4. Try manual IP address entry

### Access Denied

**Problem**: 403 Forbidden error

**Solutions**:
1. Check collection visibility (must be public)
2. Verify user is whitelisted (for group collections)
3. Check user is not blocked
4. Confirm security.json is correct

### Slow Downloads

**Problem**: File downloads are very slow

**Solutions**:
1. Check network signal strength
2. Use WiFi Direct instead of Bluetooth
3. Enable compression
4. Use BitTorrent for large files
5. Check for bandwidth throttling

### Incomplete File Tree

**Problem**: Not all files showing remotely

**Solutions**:
1. Rescan collection on source device
2. Verify tree-data.js is up to date
3. Check file permissions
4. Refresh remote collection list

## Future Enhancements

### Planned Features

1. **Push Notifications**: Notify when new collections available
2. **Sync Protocol**: Bidirectional sync between devices
3. **Offline Queue**: Queue downloads for when device reconnects
4. **Bandwidth Management**: Adaptive bandwidth allocation
5. **Multi-Source Downloads**: Download same file from multiple peers
6. **Collection Subscriptions**: Auto-sync favorited collections
7. **Version Control**: Track collection changes over time
8. **Conflict Resolution**: Merge changes from multiple sources

## Related Documentation

- [Architecture](architecture.md) - System design
- [Security Model](security-model.md) - Security details
- [API Reference](api-reference.md) - Java API
- [User Guide](user-guide.md) - User instructions
