# I2P Integration for Geogram Android

## Overview

This document describes the integration of I2P (Invisible Internet Project) networking into the Geogram Android application. I2P enables secure, anonymous peer-to-peer communication over the internet, extending Geogram's reach beyond local WiFi and Bluetooth Low Energy (BLE) connectivity.

## Motivation

Geogram currently supports two connectivity modes:

1. **WiFi**: High-speed local network communication via HTTP API (port 45678)
2. **BLE**: Low-power proximity-based communication for device discovery

I2P adds a third connectivity mode:

3. **I2P**: Global internet connectivity with privacy-preserving, censorship-resistant routing

### Use Cases

- **Remote Collections Access**: Access collections from devices across the internet without exposing IP addresses
- **Internet Fallback**: Communicate with known devices when WiFi is unavailable
- **Privacy Protection**: All I2P traffic is encrypted and routed through multiple relays (garlic routing)
- **Censorship Resistance**: I2P operates as a hidden network, making it difficult to block

## I2P Technology Basics

### What is I2P?

I2P is an anonymous overlay network that provides:

- **End-to-end encryption**: All traffic is encrypted
- **Garlic routing**: Messages bundled together and routed through multiple relays
- **Hidden services**: Servers accessible via .i2p addresses without revealing location
- **Distributed architecture**: No central servers, fully peer-to-peer

### I2P Destinations

Each I2P endpoint has a cryptographic identity called a "destination":

- **Full destination**: 516-character Base64 string (public key + signing key + certificate)
- **Base32 address**: 52-character human-readable address ending in `.b32.i2p`
- **Hostname**: Custom `.i2p` hostname via address book (optional)

Example:
```
Full: ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p
Base32: ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p
```

### SAM Bridge Protocol

The SAM (Simple Anonymous Messaging) bridge is I2P's application interface:

- **Port**: 7656 (default)
- **Protocol**: Text-based, similar to SMTP
- **Operations**: Create sessions, stream connections, send/receive datagrams
- **Language agnostic**: Works from any programming language with socket support

## Architecture Design

### Component Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Geogram Android                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │           ConnectionManager                        │  │
│  │  (Routes requests: WiFi → I2P → BLE)              │  │
│  └───────────────────────────────────────────────────┘  │
│           │              │              │                │
│     ┌─────┴─────┐   ┌────┴────┐   ┌────┴────┐          │
│     │  WiFi     │   │  I2P    │   │  BLE    │          │
│     │  Service  │   │ Service │   │ Service │          │
│     └───────────┘   └─────────┘   └─────────┘          │
│                          │                               │
│                     ┌────┴─────┐                        │
│                     │ SAM      │                        │
│                     │ Bridge   │                        │
│                     └──────────┘                        │
│                          │                               │
└──────────────────────────┼───────────────────────────────┘
                           │
                      ┌────┴─────┐
                      │ I2P      │
                      │ Router   │
                      │ (i2pd)   │
                      └──────────┘
                           │
                      ╔════╧════╗
                      ║ Internet║
                      ╚═════════╝
```

### Core Components

#### 1. I2PService

Main service that manages I2P connectivity lifecycle.

**Responsibilities:**
- Start/stop I2P router (i2pd)
- Manage SAM bridge connection
- Generate and persist I2P destination
- Monitor I2P tunnel status
- Handle battery-based auto-disconnect

**Key Methods:**
```java
void startI2P()                    // Initialize I2P router
void stopI2P()                     // Gracefully shutdown I2P
String getI2PDestination()         // Get this device's I2P address
boolean isI2PReady()               // Check if tunnels are ready
void setEnabled(boolean enabled)   // User preference toggle
```

#### 2. SAMBridge

Low-level SAM protocol implementation for communicating with I2P router.

**Responsibilities:**
- Establish TCP connection to SAM bridge (port 7656)
- Create I2P sessions (STREAM for HTTP, DATAGRAM for discovery)
- Forward HTTP traffic through I2P tunnels
- Parse SAM protocol responses

**Key Methods:**
```java
void connect()                           // Connect to SAM bridge
String createSession(String nickname)    // Create SAM session
Socket createStreamConnection(String dest) // Open I2P stream
void sendDatagram(String dest, byte[] data) // Send I2P datagram
```

#### 3. I2PDestination

Manages I2P destination identity and persistence.

**Responsibilities:**
- Generate new I2P key pairs on first run
- Save destination to persistent storage
- Derive Base32 address from full destination
- Validate destination formats

**Storage Location:**
```
/data/data/offgrid.geogram/files/i2p/destination.dat
```

**Key Methods:**
```java
static String generateDestination()     // Create new I2P identity
static String getFullDestination()      // Get 516-char destination
static String getBase32Address()        // Get .b32.i2p address
static void saveDestination(String dest) // Persist to storage
```

#### 4. I2PHttpClient

HTTP client that routes requests through I2P tunnels.

**Responsibilities:**
- Connect to remote I2P destinations
- Send HTTP GET/POST requests over I2P
- Handle I2P-specific timeouts (60-90 seconds)
- Parse responses

**Key Methods:**
```java
String get(String i2pDest, String path)    // HTTP GET over I2P
String post(String i2pDest, String path, String body) // HTTP POST
byte[] downloadFile(String i2pDest, String path) // Download over I2P
```

#### 5. I2PHttpServer

Extension to SimpleSparkServer that accepts incoming I2P connections.

**Responsibilities:**
- Listen for incoming I2P STREAM connections
- Map I2P destinations to device npubs for permission checks
- Forward requests to existing Spark HTTP handlers
- Return responses through I2P tunnels

**Integration Point:**
```java
// In SimpleSparkServer.java
if (connectionSource.equals("i2p")) {
    String requestingI2PDest = getI2PDestination(connection);
    Device device = findDeviceByI2PDest(requestingI2PDest);
    String requestingNpub = device != null ? device.getProfileNpub() : null;
    // Check permissions...
}
```

#### 6. BatteryMonitorService

Background service that monitors battery level and manages I2P lifecycle.

**Responsibilities:**
- Register battery level broadcast receiver
- Disconnect I2P when battery < 10%
- Reconnect I2P when battery > 15% (with 5% hysteresis)
- Show notifications for battery-related I2P state changes

**Key Methods:**
```java
void onBatteryChanged(int level)        // Handle battery level changes
void checkBatteryAndManageI2P()         // Apply disconnect/reconnect logic
void showLowBatteryNotification()       // Notify user of I2P disconnect
```

**Configuration:**
```java
private static final int BATTERY_DISCONNECT_THRESHOLD = 10; // 10%
private static final int BATTERY_RECONNECT_THRESHOLD = 15;  // 15%
```

#### 7. ConnectionManager

Smart routing layer that selects the best connectivity method.

**Responsibilities:**
- Attempt WiFi first (fastest, lowest latency)
- Fall back to I2P if WiFi unavailable but I2P destination known
- Fall back to BLE for local discovery only
- Cache connection preferences per device

**Connection Priority Logic:**
```java
ConnectionMethod selectConnection(Device device) {
    if (device.hasWiFiIP() && wifiAvailable()) {
        return ConnectionMethod.WIFI;
    } else if (device.hasI2PDestination() && i2pReady()) {
        return ConnectionMethod.I2P;
    } else if (device.isInBLERange()) {
        return ConnectionMethod.BLE;
    }
    return ConnectionMethod.NONE;
}
```

### Data Model Changes

#### Device.java Extensions

Add I2P destination field to Device class:

```java
public class Device {
    // Existing fields...
    private String profileNpub;
    private String wifiIp;

    // NEW: I2P support
    private String i2pDestination; // Base32 .b32.i2p address
    private long i2pDestinationTimestamp; // When destination was last updated

    public String getI2PDestination() {
        return i2pDestination;
    }

    public void setI2PDestination(String destination) {
        this.i2pDestination = destination;
        this.i2pDestinationTimestamp = System.currentTimeMillis();
    }

    public boolean hasI2PDestination() {
        return i2pDestination != null && !i2pDestination.isEmpty();
    }
}
```

#### Profile JSON Extensions

Extend HTTP API `/api/profile` response to include I2P destination:

```json
{
  "npub": "npub1...",
  "nickname": "Alice",
  "callsign": "KN4CK",
  "description": "Off-grid communications enthusiast",
  "profilePicture": "/api/profile-picture",
  "preferredColor": "#FF6B6B",
  "i2p": {
    "destination": "ukeu3k5oycgaauneqgtnvselmt4yemvoilkln7jpvamvfx7dnkdq.b32.i2p",
    "enabled": true,
    "lastSeen": 1699564800000
  }
}
```

## Discovery Mechanism

I2P destinations are discovered through local WiFi profile exchange.

### Discovery Flow

```
Device A (WiFi: 192.168.1.100)          Device B (WiFi: 192.168.1.101)
     │                                           │
     │  1. Discover via WiFi/BLE                │
     ├──────────────────────────────────────────>│
     │                                           │
     │  2. Fetch profile via WiFi                │
     │     GET /api/profile                      │
     ├──────────────────────────────────────────>│
     │                                           │
     │  3. Receive profile with I2P dest         │
     │<──────────────────────────────────────────┤
     │  {                                        │
     │    "npub": "npub1...",                    │
     │    "i2p": {                               │
     │      "destination": "abc123.b32.i2p"      │
     │    }                                      │
     │  }                                        │
     │                                           │
     │  4. Save I2P dest to Device cache         │
     │     device.setI2PDestination(...)         │
     │                                           │
     │  [Devices go offline from local WiFi]     │
     │                                           │
     │  5. Later: Connect via I2P                │
     │     GET http://abc123.b32.i2p/api/collections
     ├─────────────────(I2P Network)────────────>│
     │<─────────────────(I2P Network)────────────┤
     │                                           │
```

### Key Points

1. **Local Discovery First**: Devices must meet locally (WiFi or BLE) at least once to exchange I2P destinations
2. **Persistent Cache**: I2P destinations are cached indefinitely in Device objects and RemoteProfileCache
3. **Opportunistic Updates**: I2P destinations are refreshed whenever WiFi reconnects
4. **Manual Entry**: Future enhancement could allow manual I2P destination entry

## Battery Management

### Rationale

I2P maintains persistent tunnels that consume battery through:
- **CPU**: Cryptographic operations (AES, ElGamal)
- **Network**: Constant relay participation
- **Memory**: Routing tables and tunnel management

### Implementation Strategy

#### Disconnect Threshold: 10%

When battery drops below 10%:
1. BatteryMonitorService receives BATTERY_LOW broadcast
2. Calls `I2PService.stopI2P()`
3. Shows notification: "I2P disabled to conserve battery"
4. Device remains accessible via WiFi/BLE

#### Reconnect Threshold: 15%

When battery rises above 15% (after charging):
1. BatteryMonitorService detects battery increase
2. Checks if I2P was previously enabled by user
3. Calls `I2PService.startI2P()`
4. Shows notification: "I2P reconnected"

#### Hysteresis

5% gap (10% disconnect, 15% reconnect) prevents rapid toggling around threshold.

#### User Preferences

Users can:
- Disable I2P entirely (Settings → I2P → Enable I2P)
- Change disconnect threshold (default 10%, range 5-20%)
- Disable battery-based auto-disconnect (advanced setting)

### Battery Monitoring Code

```java
public class BatteryMonitorService extends Service {
    private static final int DISCONNECT_THRESHOLD = 10;
    private static final int RECONNECT_THRESHOLD = 15;

    private BroadcastReceiver batteryReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            int level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
            int scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
            int batteryPercent = (int) ((level / (float) scale) * 100);

            checkBatteryAndManageI2P(batteryPercent);
        }
    };

    private void checkBatteryAndManageI2P(int batteryPercent) {
        I2PService i2pService = I2PService.getInstance(this);

        if (batteryPercent < DISCONNECT_THRESHOLD && i2pService.isRunning()) {
            Log.i("BatteryMonitor", "Battery below " + DISCONNECT_THRESHOLD + "%, stopping I2P");
            i2pService.stopI2P();
            showNotification("I2P disabled to conserve battery");
        } else if (batteryPercent > RECONNECT_THRESHOLD && !i2pService.isRunning()) {
            // Only reconnect if user has I2P enabled in preferences
            SharedPreferences prefs = getSharedPreferences("i2p_prefs", MODE_PRIVATE);
            boolean userEnabledI2P = prefs.getBoolean("i2p_enabled", true);

            if (userEnabledI2P) {
                Log.i("BatteryMonitor", "Battery above " + RECONNECT_THRESHOLD + "%, starting I2P");
                i2pService.startI2P();
                showNotification("I2P reconnected");
            }
        }
    }
}
```

## Security Considerations

### Threat Model

#### Threats Mitigated by I2P

1. **IP Address Exposure**: I2P hides device IP addresses from collection servers and other peers
2. **Traffic Analysis**: Garlic routing makes it difficult to correlate requests with responses
3. **Censorship**: I2P operates as a hidden network, difficult for ISPs to block
4. **Man-in-the-Middle**: All I2P connections are encrypted end-to-end

#### Threats NOT Mitigated

1. **Compromised Devices**: If Device A is compromised, attacker can access collections it has permission for
2. **Nostr Key Compromise**: If nsec is stolen, attacker can impersonate user
3. **Local Network Attacks**: WiFi traffic is not encrypted by default (use WPA2/3)
4. **Social Engineering**: Users can be tricked into granting collection permissions

### Access Control

#### Collection Permission Validation

All collection API endpoints validate permissions based on:

1. **Device Identification**:
   - WiFi: Map IP address → Device → npub
   - I2P: Map I2P destination → Device → npub
   - BLE: Not applicable (BLE doesn't transfer collections)

2. **Permission Check**:
   ```java
   boolean hasCollectionAccess(CollectionSecurity security, String requestingNpub) {
       if (security.getVisibility() == Visibility.PUBLIC) {
           return true;
       } else if (security.getVisibility() == Visibility.GROUP) {
           List<String> whitelist = security.getWhitelistedUsers();
           return whitelist != null && whitelist.contains(requestingNpub);
       }
       return false; // PRIVATE
   }
   ```

3. **Endpoint Protection**:
   - `/api/collections` - List only accessible collections
   - `/api/collections/:npub/files` - Check permission before listing
   - `/api/collections/:npub/file/*` - Check permission before serving
   - `/api/collections/:npub/thumbnail/*` - Check permission before serving

#### I2P-Specific Considerations

**Challenge**: I2P destinations are pseudonymous addresses, not cryptographic proofs.

**Attack Scenario**: Attacker creates new I2P destination, claims to be Device B.

**Mitigation**:
1. **Local Discovery Requirement**: Devices must exchange I2P destinations locally via WiFi first
2. **Nostr Signature Verification**: Future enhancement to require Nostr event signatures for profile updates
3. **Trust on First Use (TOFU)**: First I2P destination received for a npub is trusted, changes require local confirmation

### Privacy Considerations

#### Information Leaked via I2P

1. **Collection Metadata**: Titles, file counts, thumbnail availability (even for PRIVATE collections if attacker knows I2P destination)
2. **Active Hours**: When device responds to I2P requests reveals user's active hours
3. **Device Fingerprinting**: HTTP headers, API response timings can fingerprint device type

#### Recommendations

1. **Minimize Metadata**: Don't include sensitive info in collection titles
2. **Request Rate Limiting**: Prevent brute-force scanning of I2P addresses
3. **Random Response Delays**: Add jitter to API responses to prevent timing analysis
4. **Nostr Identity Binding**: Require Nostr signatures for profile updates to prevent impersonation

## Implementation Phases

### Phase 1: Core I2P Infrastructure (3-4 days)

**Goal**: Basic I2P connectivity without UI integration.

**Tasks**:
1. Add I2P SAM library dependency to `app/build.gradle.kts`
2. Create `I2PService.java` - Main service for I2P lifecycle management
3. Create `SAMBridge.java` - Low-level SAM protocol implementation
4. Create `I2PDestination.java` - Destination generation and persistence
5. Create `I2PHttpClient.java` - HTTP client for I2P requests
6. Test SAM bridge connection and destination generation

**Deliverables**:
- I2P router starts on app launch
- I2P destination generated and saved
- Can establish SAM session
- Logs show tunnel readiness

**Testing**:
```bash
# Check if I2P destination was generated
adb shell cat /data/data/offgrid.geogram/files/i2p/destination.dat

# Check logcat for I2P startup
adb logcat | grep I2P
```

### Phase 2: HTTP Server I2P Integration (2-3 days)

**Goal**: SimpleSparkServer accepts incoming I2P connections.

**Tasks**:
1. Extend `SimpleSparkServer.java` to listen on I2P SAM STREAM
2. Implement `findDeviceByI2PDest(String i2pDest)` method
3. Update permission checks in all collection endpoints
4. Add I2P source detection to request handlers
5. Test incoming I2P requests

**Deliverables**:
- Server accepts I2P connections on port 45678
- Permission checks work for I2P requestors
- Logs show I2P destination of incoming connections

**Testing**:
```bash
# From another device with I2P
curl http://ukeu3k5o...dnkdq.b32.i2p:45678/api/profile
```

### Phase 3: Battery Management (2 days)

**Goal**: I2P automatically disconnects on low battery.

**Tasks**:
1. Create `BatteryMonitorService.java`
2. Register battery level broadcast receiver
3. Implement disconnect logic (< 10%)
4. Implement reconnect logic (> 15%)
5. Add user notifications for state changes
6. Test battery thresholds

**Deliverables**:
- I2P stops when battery < 10%
- I2P restarts when battery > 15% (if previously enabled)
- Notifications shown to user

**Testing**:
```bash
# Simulate low battery
adb shell dumpsys battery set level 9
adb logcat | grep I2P

# Simulate charging
adb shell dumpsys battery set level 20
adb logcat | grep I2P

# Reset battery simulation
adb shell dumpsys battery reset
```

### Phase 4: Profile Extensions (2 days)

**Goal**: Devices share I2P destinations in profiles.

**Tasks**:
1. Add `i2pDestination` field to `Device.java`
2. Update HTTP API `/api/profile` to include I2P destination
3. Update `RemoteProfileCache.java` to store I2P destinations
4. Update `DevicesWithinReachFragment.java` to fetch and cache I2P addresses
5. Test profile exchange with I2P info

**Deliverables**:
- `/api/profile` response includes I2P destination
- I2P destination cached in Device objects
- UI shows I2P status indicator (green dot if I2P available)

**Testing**:
```bash
# Fetch profile from device
curl http://192.168.1.100:45678/api/profile | jq .i2p
```

### Phase 5: Connection Manager (3-4 days)

**Goal**: Intelligent routing between WiFi, I2P, and BLE.

**Tasks**:
1. Create `ConnectionManager.java`
2. Implement connection priority logic (WiFi → I2P → BLE)
3. Update `DeviceProfileFragment.java` to use ConnectionManager
4. Update `CollectionBrowserFragment.java` to use ConnectionManager
5. Add connection status indicators to UI
6. Test failover scenarios

**Deliverables**:
- Collections load via I2P when WiFi unavailable
- UI shows current connection method (WiFi/I2P/BLE badge)
- Seamless failover between connection types

**Testing Scenarios**:
1. Device A and B on same WiFi → Should use WiFi
2. Device A and B on different WiFi but both online → Should use I2P
3. Device A offline, B online → Should show "offline" status
4. Device A and B in BLE range only → Should use BLE for discovery

### Phase 6: Settings UI (2 days)

**Goal**: User controls for I2P configuration.

**Tasks**:
1. Create `I2PSettingsFragment.java`
2. Add I2P enable/disable toggle
3. Add battery disconnect threshold slider (5-20%)
4. Add "My I2P Address" display with copy button
5. Add I2P status indicator (Connected/Connecting/Disconnected)
6. Add "Test I2P Connection" button
7. Update Settings menu to include I2P section

**Deliverables**:
- Settings → I2P panel accessible
- Users can enable/disable I2P
- Users can customize battery threshold
- Users can copy their I2P address for manual sharing

**UI Mockup**:
```
┌─────────────────────────────────────┐
│ ← I2P Settings                      │
├─────────────────────────────────────┤
│                                     │
│ Enable I2P           [✓]           │
│                                     │
│ My I2P Address                      │
│ ukeu3k5o...dnkdq.b32.i2p    [Copy] │
│                                     │
│ Status: Connected ●                 │
│                                     │
│ Battery Disconnect Threshold        │
│ ─────●─────────────────── 10%      │
│                                     │
│ Auto-reconnect after charging [✓]  │
│                                     │
│ [ Test I2P Connection ]             │
│                                     │
└─────────────────────────────────────┘
```

### Phase 7: Testing & Debugging (2-3 days)

**Goal**: Comprehensive end-to-end testing.

**Test Cases**:

1. **Initial Setup**:
   - [ ] I2P destination generated on first app launch
   - [ ] I2P router starts automatically
   - [ ] Destination persists across app restarts

2. **Local Discovery**:
   - [ ] Device A discovers Device B via WiFi
   - [ ] Device A fetches Device B's profile
   - [ ] Profile includes I2P destination
   - [ ] I2P destination saved to cache

3. **I2P Connection**:
   - [ ] Device A can connect to Device B via I2P
   - [ ] Collections load over I2P connection
   - [ ] Files download over I2P connection
   - [ ] Thumbnails load over I2P connection

4. **Permission Validation**:
   - [ ] PUBLIC collections accessible via I2P
   - [ ] PRIVATE collections blocked via I2P
   - [ ] GROUP collections accessible to whitelisted npubs via I2P
   - [ ] GROUP collections blocked for non-whitelisted npubs via I2P

5. **Battery Management**:
   - [ ] I2P disconnects when battery < 10%
   - [ ] I2P stays disconnected when battery 10-15%
   - [ ] I2P reconnects when battery > 15%
   - [ ] User notifications shown

6. **Connection Failover**:
   - [ ] WiFi preferred when available
   - [ ] I2P used when WiFi unavailable but I2P destination known
   - [ ] BLE used for local discovery only
   - [ ] Connection method shown in UI

7. **Settings**:
   - [ ] I2P can be disabled by user
   - [ ] Battery threshold can be changed
   - [ ] I2P address can be copied
   - [ ] Test connection button works

8. **Edge Cases**:
   - [ ] App handles I2P router failure gracefully
   - [ ] SAM bridge disconnection doesn't crash app
   - [ ] Long I2P connection timeouts don't block UI
   - [ ] Profile fetch failure doesn't prevent WiFi access

### Phase 8: Performance Optimization (2 days)

**Goal**: Minimize I2P overhead and improve UX.

**Optimizations**:

1. **Connection Pooling**: Reuse I2P streams for multiple HTTP requests
2. **Lazy Loading**: Don't start I2P until actually needed
3. **Background Threads**: All I2P operations run off main thread
4. **Timeout Tuning**: Set appropriate timeouts for I2P connections (60-90s)
5. **Request Caching**: Cache collection metadata to reduce I2P requests
6. **Tunnel Prewarming**: Establish tunnels in advance when I2P destination known

**Performance Targets**:
- I2P connection establishment: < 60 seconds
- HTTP GET over I2P: < 30 seconds
- File download (1 MB): < 2 minutes
- Thumbnail load: < 10 seconds

### Phase 9: Documentation & Release (1 day)

**Goal**: User-facing documentation and release notes.

**Tasks**:
1. Write user guide: "Using I2P with Geogram"
2. Write troubleshooting guide for I2P issues
3. Update README.md with I2P feature description
4. Add I2P section to FAQ
5. Create release notes for I2P launch
6. Test on multiple Android versions (8.0-14.0)

**Release Notes Template**:
```markdown
## Version X.X.X - I2P Integration

### New Features
- **I2P Anonymous Networking**: Connect to remote devices over the internet using I2P
- **Battery-Conscious I2P**: Automatically disconnect I2P when battery is low
- **I2P Settings**: Configure I2P preferences in Settings → I2P

### How It Works
1. Devices exchange I2P addresses when connected locally via WiFi
2. When on different networks, devices can communicate via I2P
3. I2P provides privacy-preserving, censorship-resistant connectivity

### Requirements
- Android 8.0+ (API level 26+)
- Internet connection for I2P
- ~50-100 MB storage for I2P router data

### Known Limitations
- I2P connections can take 30-90 seconds to establish
- Requires local WiFi meeting at least once for discovery
- Higher battery consumption compared to WiFi/BLE
```

## Timeline Summary

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Core I2P Infrastructure | 3-4 days | 4 days |
| Phase 2: HTTP Server Integration | 2-3 days | 7 days |
| Phase 3: Battery Management | 2 days | 9 days |
| Phase 4: Profile Extensions | 2 days | 11 days |
| Phase 5: Connection Manager | 3-4 days | 15 days |
| Phase 6: Settings UI | 2 days | 17 days |
| Phase 7: Testing & Debugging | 2-3 days | 20 days |
| Phase 8: Performance Optimization | 2 days | 22 days |
| Phase 9: Documentation & Release | 1 day | 23 days |

**Total Estimated Duration**: 19-23 days (~3-4 weeks)

## Dependencies

### External Libraries

1. **i2p.jar** or **i2pd-android**:
   - Option A: Embed I2P Java router (i2p.jar) - 40 MB
   - Option B: Use i2pd-android IPC - 15 MB, requires separate app
   - **Recommendation**: Option A for simplicity

2. **SAM Bridge Library**:
   - Option A: net.i2p.client (official)
   - Option B: Custom implementation (lighter)
   - **Recommendation**: Option B for Android

### System Requirements

- **Android Version**: 8.0+ (API 26+)
- **Permissions**: INTERNET, ACCESS_NETWORK_STATE, BATTERY_STATS
- **Storage**: ~50-100 MB for I2P router data
- **RAM**: ~100-150 MB additional

### Build Configuration

```kotlin
// app/build.gradle.kts
dependencies {
    implementation("net.i2p:i2p:2.4.0") // I2P router
    implementation("net.i2p.client:streaming:2.4.0") // SAM client
}

android {
    defaultConfig {
        // Exclude unnecessary I2P classes
        packagingOptions {
            resources {
                excludes += setOf(
                    "META-INF/LICENSE",
                    "META-INF/NOTICE",
                    "META-INF/licenses/**"
                )
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

#### 1. I2P Router Fails to Start

**Symptoms**: "I2P Disconnected" status, no tunnels created

**Causes**:
- No internet connection
- SAM bridge port 7656 blocked
- Insufficient storage space
- I2P data corruption

**Solutions**:
```bash
# Check I2P logs
adb shell cat /data/data/offgrid.geogram/files/i2p/router.log

# Clear I2P data
adb shell rm -rf /data/data/offgrid.geogram/files/i2p/*

# Restart app
adb shell am force-stop offgrid.geogram
adb shell am start -n offgrid.geogram/.MainActivity
```

#### 2. I2P Connections Time Out

**Symptoms**: "Connection timeout" when accessing remote collections

**Causes**:
- I2P network congestion
- Remote device offline
- Tunnels not ready

**Solutions**:
- Wait 30-90 seconds for tunnels to establish
- Check remote device is online and has I2P enabled
- Try connection again later

#### 3. High Battery Drain

**Symptoms**: Battery drops quickly with I2P enabled

**Causes**:
- I2P constantly building tunnels
- Relay participation enabled
- Old Android version (< 9.0) with poor battery optimization

**Solutions**:
- Lower battery disconnect threshold to 15%
- Disable I2P when not needed
- Ensure WiFi preferred over I2P (ConnectionManager handles this)

#### 4. Collections Not Loading via I2P

**Symptoms**: Collections visible via WiFi but not I2P

**Causes**:
- Permission check failing
- I2P destination not cached
- Collection is PRIVATE

**Debug**:
```bash
# Check device has I2P destination
adb shell content query --uri content://offgrid.geogram/devices \
  --projection i2p_destination

# Check SimpleSparkServer logs
adb logcat | grep "I2P access"
```

## Future Enhancements

### Short-Term (1-2 releases)

1. **Manual I2P Destination Entry**: Allow users to manually add I2P addresses
2. **I2P Address Book**: Custom .i2p hostnames for frequently accessed devices
3. **Connection History**: Show past I2P connections and success rates
4. **Bandwidth Limiting**: Limit I2P bandwidth to conserve data on mobile networks

### Medium-Term (3-6 releases)

1. **Nostr Signature Verification**: Require Nostr signatures for I2P destination updates
2. **Multi-Hop I2P**: Use I2P outproxy for additional anonymity
3. **I2P Relay Participation**: Contribute bandwidth to I2P network (opt-in)
4. **Offline Message Queue**: Queue messages for delivery when remote device comes online

### Long-Term (6+ releases)

1. **Hybrid Tor/I2P**: Support both Tor and I2P for redundancy
2. **Mesh Routing**: Use I2P to relay messages between non-directly connected devices
3. **Private Collections over I2P**: End-to-end encrypted collections with I2P transport
4. **Decentralized Discovery**: Use I2P's DHT for device discovery without WiFi

## References

### I2P Documentation

- [I2P Official Site](https://geti2p.net/)
- [SAM Bridge Specification](https://geti2p.net/en/docs/api/samv3)
- [I2P for Android](https://geti2p.net/en/docs/ports/android)
- [i2pd (C++ I2P Implementation)](https://i2pd.website/)

### Geogram Documentation

- [Collections Specification](../collections/README.md)
- [Profile System](../architecture/profile-system.md)
- [WiFi Discovery](../architecture/wifi-discovery.md)
- [Permission Model](../collections/security.md)

### Related Technologies

- [Nostr Protocol](https://github.com/nostr-protocol/nips)
- [Garlic Routing](https://geti2p.net/en/docs/how/garlic-routing)
- [Android Battery Optimization](https://developer.android.com/topic/performance/power)

---

**Document Version**: 1.0
**Last Updated**: 2025-11-14
**Author**: Geogram Development Team
**Status**: Planning Phase
