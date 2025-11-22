# BLE Protocol for Geogram Relay

## Overview

This document specifies the BLE (Bluetooth Low Energy) protocol used by Geogram devices (Android app and T-Dongle ESP32-S3 beacons) for peer-to-peer message exchange and relay functionality.

## BLE Service Advertisement

### Service UUID

All Geogram BLE advertisements use:
- **UUID**: `0xFFF0` (16-bit service UUID)
- **Transport**: BLE Service Data field

### Advertising Parameters

**T-Dongle ESP32-S3**:
```cpp
BLEAdvertising* adv = BLEDevice::getAdvertising();
BLEAdvertisementData advData;
advData.setFlags(0x06);  // BR/EDR Not Supported, LE General Discoverable Mode
advData.setServiceData(BLEUUID((uint16_t)0xFFF0), payload);
```

**Android App**:
- Uses standard Android BLE scanning APIs
- Filters for service UUID `0xFFF0`
- Listens for service data payloads

### Advertising Interval

**T-Dongle**:
- Scan interval: 80ms
- Scan window: 60ms
- Active scanning enabled

**Android**:
- Continuous scanning when app is active
- Background scanning with reduced frequency to save battery

## Message Format

### Payload Prefix

All BLE service data payloads MUST start with the `>` character (ASCII 0x3E):

```
Offset | Length | Field           | Description
-------|--------|-----------------|---------------------------
0      | 1      | Prefix          | 0x3E ('>') - Message marker
1-N    | N      | Content         | Message content (UTF-8)
```

**Example**:
```
>Hello World
>AA0:ALICE:BOB:ABCD
>AA1:This is a test message
```

### UTF-8 Validation

All message content MUST be valid UTF-8:
- **Allowed**: ASCII (0x20-0x7E), multi-byte UTF-8 sequences (emojis supported)
- **Rejected**: Control characters (0x00-0x1F), DEL (0x7F), malformed UTF-8
- **Maximum length**: 24 bytes total (including '>' prefix)

## Single-Packet Commands

Single-packet commands are messages that fit within a single BLE advertisement (≤23 bytes content after '>').

### Format

```
>COMMAND_TEXT
```

**Characteristics**:
- No colon (`:`) separator
- Complete message in single packet
- Minimum 8 bytes content (after '>' prefix)
- Maximum 23 bytes content (24 bytes total with '>')

### Examples

```
>PING
>ACK-msg123
>HELLO-ALICE
>STATUS-OK
```

### Detection

```cpp
bool isSingleCommand(const String& s) {
    return (s.length() > 0) && (s.indexOf(':') < 0);
}
```

## Multi-Packet Messages

Messages longer than 23 bytes are split into multiple BLE advertisements using a parcel-based protocol.

### Message ID

Each multi-packet message has a 2-letter ID from AA-ZZ:
- First letter: 'A'-'Z' (26 options)
- Second letter: 'A'-'Z' (26 options)
- Total: 676 unique message IDs
- Generated randomly per message

**Example IDs**: `AA`, `AB`, `BZ`, `ZZ`

### Packet Numbering

Packets are numbered sequentially starting from 0:
- **Packet 0**: Header packet (metadata)
- **Packet 1-N**: Data packets (message content chunks)

### Header Packet (Index 0)

**Format**:
```
><ID>0:<FROM>:<TO>:<CHECKSUM>
```

**Fields**:
- `<ID>`: 2-letter message ID (e.g., "AA")
- `0`: Packet index (always 0 for header)
- `<FROM>`: Sender callsign/ID
- `<TO>`: Destination callsign/ID
- `<CHECKSUM>`: 4-letter base-26 checksum

**Example**:
```
>AA0:ALICE-K5XYZ:BOB-N7ABC:XMPL
```

**Parsing**:
```cpp
int p1 = messageParcel.indexOf(':');         // After "AA0"
int p2 = messageParcel.indexOf(':', p1 + 1); // After "ALICE-K5XYZ"
int p3 = messageParcel.indexOf(':', p2 + 1); // After "BOB-N7ABC"

String from     = messageParcel.substring(p1 + 1, p2);  // "ALICE-K5XYZ"
String to       = messageParcel.substring(p2 + 1, p3);  // "BOB-N7ABC"
String checksum = messageParcel.substring(p3 + 1);      // "XMPL"
```

### Data Packets (Index 1-N)

**Format**:
```
><ID><INDEX>:<DATA>
```

**Fields**:
- `<ID>`: 2-letter message ID (must match header)
- `<INDEX>`: Packet number (1, 2, 3, ...)
- `<DATA>`: Message content chunk (up to 18 bytes)

**Examples**:
```
>AA1:This is the first
>AA2: chunk of the mes
>AA3:sage content here
```

**Data chunk size**: Approximately 18 bytes per packet to stay within 24-byte BLE limit.

### Complete Multi-Packet Example

**Message**: "Hello Bob, this is a longer message that needs multiple BLE packets to transmit completely!"

**Packets transmitted**:
```
>AA0:ALICE:BOB:JKLM
>AA1:Hello Bob, this i
>AA2:s a longer message
>AA3: that needs multip
>AA4:le BLE packets to
>AA5:transmit completel
>AA6:y!
```

### Checksum Calculation

Geogram uses a simple base-26 checksum for message integrity:

**Algorithm**:
```cpp
String calculateChecksum(const String& data) {
    if (data.length() == 0) return "AAAA";

    long sum = 0;
    for (size_t i = 0; i < data.length(); ++i) {
        sum += (unsigned char)data[i];
    }

    char cs[5];
    for (int i = 0; i < 4; ++i) {
        cs[i] = 'A' + (sum % 26);
        sum /= 26;
    }
    cs[4] = '\0';
    return String(cs);
}
```

**Example**:
```
Input: "Hello World"
Sum: 72+101+108+108+111+32+87+111+114+108+100 = 1052
Base-26 encoding:
  1052 % 26 = 0  → 'A'
  40   % 26 = 14 → 'O'
  1    % 26 = 1  → 'B'
  0    % 26 = 0  → 'A'
Checksum: "AOBA"
```

## Message Assembly

### Receiving Parcels

The receiver assembles multi-packet messages by:

1. **Detect header packet** (index 0) → extract `FROM`, `TO`, `CHECKSUM`, `ID`
2. **Collect data packets** (index 1-N) → store by ID and index
3. **Reassemble content** → concatenate data packets in order
4. **Verify checksum** → compare calculated vs received checksum
5. **Mark complete** → message ready for delivery

**Implementation**:
```cpp
void addMessageParcel(const String& messageParcel) {
    // Parse parcel ID: "AA5" → id="AA", index=5
    int colon = messageParcel.indexOf(':');
    String parcelId = messageParcel.substring(0, colon);

    // De-duplicate: ignore if already received
    if (messageBox.find(parcelId) != messageBox.end()) return;

    // Store parcel
    messageBox.insert({parcelId, messageParcel});

    // If index == 0, parse header
    if (index == 0) {
        // Parse FROM:TO:CHECKSUM
    }

    // Check if complete
    if (messageBox.size() >= 2 && checksum.length() > 0) {
        // Reassemble data packets
        String result;
        for (auto& kv : messageBox) {
            int idx = parseIndex(kv.first);
            if (idx >= 1) {
                result += extractData(kv.second);
            }
        }

        // Verify checksum
        if (calculateChecksum(result) == checksum) {
            message = result;
            messageCompleted = true;
        }
    }
}
```

### Packet Loss Detection

The receiver can detect missing packets by:

1. **Gap detection**: Check for missing sequence numbers
2. **Request retransmission**: Send NACK command with missing packet IDs

**Get first missing parcel**:
```cpp
String getFirstMissingParcel() const {
    if (checksum.length() == 0) return id + "0";  // Need header
    if (messageBox.size() == 1) return id + "1";  // Need first data packet

    // Find first gap in sequence
    for (int i = 0; i < messageBox.size(); ++i) {
        String key = id + String(i);
        if (messageBox.find(key) == messageBox.end()) {
            return key;
        }
    }

    // Need next sequential packet
    return id + String(messageBox.size());
}
```

**Get all missing parcels**:
```cpp
std::vector<String> getMissingParcels() const {
    std::vector<String> missing;

    // Find maximum packet index received
    int maxSeen = -1;
    for (auto& kv : messageBox) {
        int idx = parseIndex(kv.first);
        if (idx > maxSeen) maxSeen = idx;
    }

    // Check for gaps from 0 to maxSeen
    for (int i = 0; i < maxSeen; ++i) {
        String key = id + String(i);
        if (messageBox.find(key) == messageBox.end()) {
            missing.push_back(key);
        }
    }

    return missing;
}
```

## Retransmission Protocol

When packets are lost, the receiver can request retransmission.

### NACK Command Format

```
>NACK-<MESSAGE_ID>-<MISSING_PACKETS>
```

**Example**:
```
>NACK-AA-0,3,5
```

Requests retransmission of packets `AA0`, `AA3`, and `AA5`.

### Retransmission Response

The sender retransmits only the requested packets:
```
>AA0:ALICE:BOB:JKLM
>AA3: that needs multip
>AA5:transmit completel
```

## Deduplication

BLE packets may be received multiple times (especially with overlapping beacon ranges). Deduplication prevents processing duplicates.

### Payload-Based Deduplication

**Strategy**: Track recently seen payloads (ignore MAC address).

**Implementation**:
```cpp
struct SeenEntry {
    String key;      // Full payload including '>'
    uint32_t ts;     // Timestamp when first seen
};

SeenEntry g_seen[128];  // Circular buffer
uint8_t g_seen_head = 0;

bool seen_recently_payload(const String& payload, uint32_t now_ms) {
    // Check if payload seen within dedup window (default 2000ms)
    for (uint8_t i = 0; i < 128; ++i) {
        if (g_seen[i].key.length() == 0) continue;

        // Expire old entries
        if ((now_ms - g_seen[i].ts) > DEDUP_WINDOW_MS) {
            g_seen[i].key = "";
            continue;
        }

        // Check for duplicate
        if (g_seen[i].key == payload) return true;
    }

    // Not seen recently, record it
    g_seen[g_seen_head] = {payload, now_ms};
    g_seen_head = (g_seen_head + 1) & 0x7F;  // Wrap at 128
    return false;
}
```

**Dedup window**: 2000ms default (configurable).

### Why Ignore MAC Address?

- BLE beacons use randomly rotating MAC addresses (privacy feature)
- Same device may advertise with different MACs over time
- Payload content is what matters for deduplication

## In-Flight Message Tracking

The receiver maintains a pool of partially assembled messages.

### Message Slots

**Capacity**: 676 slots (26×26 = AA-ZZ message IDs)

```cpp
struct Inflight {
    BluetoothMessage bm;      // Assembled message state
    uint32_t lastTouchMs;     // Last packet received timestamp
};

Inflight g_inflight[26*26];  // One slot per possible message ID
```

### Slot Mapping

```cpp
int inflight_index_2(const char* id2) {
    char a = id2[0], b = id2[1];
    if (a < 'A' || a > 'Z' || b < 'A' || b > 'Z') return -1;
    return (a - 'A') * 26 + (b - 'A');
}
```

**Example**:
- `AA` → index 0
- `AB` → index 1
- `BA` → index 26
- `ZZ` → index 675

### Message Timeout

Messages that don't complete within 10 minutes are automatically purged:

```cpp
#define INFLIGHT_TTL_MS (10UL * 60UL * 1000UL)  // 10 minutes

void inflight_sweep(uint32_t now) {
    for (auto& slot : g_inflight) {
        if (slot.lastTouchMs == 0) continue;

        if (!slot.bm.isMessageCompleted() &&
            (now - slot.lastTouchMs) >= INFLIGHT_TTL_MS) {
            // Reset slot
            slot.bm.~BluetoothMessage();
            new (&slot.bm) BluetoothMessage();
            slot.lastTouchMs = 0;
        }
    }
}
```

## Event Bus Architecture

The T-Dongle uses an event-driven architecture to decouple BLE reception from message processing.

### Event Types

```cpp
enum BleEventType {
    BLE_EVT_SINGLE_TEXT,    // Single-packet command received
    BLE_EVT_MESSAGE_DONE    // Multi-packet message completed
};
```

### Event Queue

```cpp
BleEvent g_evt_q[32];           // Event queue (ring buffer)
volatile uint16_t g_evt_head = 0;
volatile uint16_t g_evt_tail = 0;
uint32_t g_evt_dropped = 0;     // Counter for dropped events
```

### Single Text Event

```cpp
struct BleEventSingleText {
    char text[256];         // Message text (including '>' prefix)
    uint16_t text_len;      // Actual text length
    int8_t rssi;            // Signal strength
    uint8_t mac[6];         // Sender MAC address
};
```

**Example**:
```cpp
BleEvent ev;
ev.type = BLE_EVT_SINGLE_TEXT;
strncpy(ev.data.single.text, ">HELLO-WORLD", 255);
ev.data.single.text_len = 12;
ev.data.single.rssi = -45;
memcpy(ev.data.single.mac, sender_mac, 6);
```

### Message Done Event

```cpp
struct BleEventMessageDone {
    char id[3];             // Message ID (e.g., "AA")
    char from[32];          // Sender callsign
    char to[32];            // Destination callsign
    char checksum[5];       // 4-letter checksum + null
    uint32_t msg_len;       // Total message length
    char snippet[256];      // First 255 bytes of message
};
```

**Example**:
```cpp
BleEvent ev;
ev.type = BLE_EVT_MESSAGE_DONE;
strncpy(ev.data.done.id, "AA", 2);
strncpy(ev.data.done.from, "ALICE-K5XYZ", 31);
strncpy(ev.data.done.to, "BOB-N7ABC", 31);
strncpy(ev.data.done.checksum, "JKLM", 4);
ev.data.done.msg_len = 89;
strncpy(ev.data.done.snippet, "Hello Bob, this is...", 255);
```

### Event Delivery

```cpp
void ble_tick(void) {
    BleEvent e;
    int budget = 12;  // Process up to 12 events per tick

    while (budget-- > 0 && q_pop(&e)) {
        // Deliver to all subscribers
        for (int i = 0; i < BLE_MAX_SUBSCRIBERS; ++i) {
            if (g_subs[i].used && g_subs[i].cb) {
                g_subs[i].cb(&e, g_subs[i].ctx);
            }
        }
    }
}
```

**Subscribers**:
```cpp
typedef void (*BleEventCb)(const BleEvent* evt, void* user_ctx);

int ble_subscribe(BleEventCb cb, void* user_ctx) {
    // Register callback, returns subscription token
}

void ble_unsubscribe(int token) {
    // Unregister callback
}
```

## Transmission

### Burst Transmission

Messages are transmitted in short bursts to maximize reception:

```cpp
void adv_send_text_burst(const String& text, uint32_t duration_ms) {
    BLEAdvertising* adv = BLEDevice::getAdvertising();

    // Ensure '>' prefix
    std::string payload = text.c_str();
    if (payload.empty() || payload[0] != '>') {
        payload.insert(payload.begin(), '>');
    }

    // Limit to 24 bytes
    if (payload.size() > ADV_TEXT_MAX) {
        payload.resize(ADV_TEXT_MAX);
    }

    // Configure advertising data
    BLEAdvertisementData advData;
    advData.setFlags(0x06);
    advData.setServiceData(BLEUUID((uint16_t)0xFFF0), payload);

    // Start advertising
    adv->stop();
    adv->setAdvertisementData(advData);
    adv->start();

    // Advertise for specified duration
    delay(duration_ms);

    // Stop advertising
    adv->stop();
}
```

**Default burst duration**: 100ms per packet.

### Pause Scanning During Send

To avoid interference, scanning is paused during transmission:

```cpp
int ble_send_text(const uint8_t* data, size_t len, bool pauseDuringSend) {
    bool resume = false;

    if (pauseDuringSend && ble_is_listening()) {
        ble_stop_listening();
        resume = true;
    }

    // Send message
    adv_send_text_burst(text, 100);

    if (resume) {
        ble_start_listening(true);
    }

    return (int)len;
}
```

### Multi-Packet Transmission

For messages requiring multiple packets:

```cpp
void sendMultiPacketMessage(const String& from, const String& to, const String& message) {
    BluetoothMessage bm(from, to, message, false);

    // Get all parcels
    std::vector<String> parcels = bm.getMessageParcels();

    // Send each parcel with delay
    for (const String& parcel : parcels) {
        ble_send_text((const uint8_t*)parcel.c_str(), parcel.length(), true);
        delay(150);  // 150ms between packets
    }
}
```

**Inter-packet delay**: 150ms recommended to allow receivers to process.

## RSSI and Range

### Signal Strength

RSSI (Received Signal Strength Indicator) is captured with each received packet:

```cpp
int8_t rssi = advertisedDevice.getRSSI();
```

**Typical values**:
- `-30 to -50 dBm`: Very close (< 1 meter)
- `-50 to -70 dBm`: Close range (1-5 meters)
- `-70 to -85 dBm`: Medium range (5-15 meters)
- `-85 to -100 dBm`: Long range (15-30 meters)
- `< -100 dBm`: Very weak, unreliable

### Range Estimation

Approximate distance can be estimated from RSSI:

```
distance (meters) ≈ 10 ^ ((TxPower - RSSI) / (10 * PathLoss))
```

Where:
- `TxPower`: Transmit power at 1 meter (typically -59 dBm for BLE)
- `PathLoss`: Environmental factor (2.0 for free space, 3.0-4.0 for indoor)

## Performance Characteristics

### Throughput

**Single packet**: 23 bytes content, ~100ms burst = **230 bytes/sec**

**Multi-packet**:
- 18 bytes per packet
- 150ms per packet (100ms burst + 50ms gap)
- Throughput: **120 bytes/sec**

**Example**:
- 100-byte message: 6 packets = ~900ms total
- 1000-byte message: 56 packets = ~8.4 seconds total

### Reliability

**Packet loss mitigation**:
1. **Burst advertising**: 100ms per packet increases reception probability
2. **Deduplication**: Prevents processing duplicate receptions
3. **NACK retransmission**: Recovers from packet loss
4. **Timeout**: 10-minute window for assembly

**Expected reliability**: >95% packet delivery in good conditions (RSSI > -80 dBm)

### Battery Impact

**T-Dongle ESP32-S3**:
- Continuous scanning: ~50mA current draw
- Advertising burst: ~80mA peak during transmission
- Idle (not scanning): ~20mA

**Android**:
- Continuous BLE scanning: Minimal impact (~2-5% battery per hour)
- Background scanning: Negligible (<1% per hour)

## Security Considerations

### Current Protocol

**No encryption**: The current BLE protocol transmits messages in plaintext.

**Visibility**: Anyone scanning for UUID 0xFFF0 can receive messages.

### Future Enhancements

For relay messages containing sensitive data:

1. **End-to-end encryption**: Encrypt message content before BLE transmission
2. **Message signatures**: Add NOSTR signatures to header packets
3. **Replay protection**: Include timestamps and sequence numbers
4. **MAC filtering**: Optionally limit accepted devices by MAC whitelist

### Relay-Specific Security

When implementing relay functionality:

1. **Verify signatures**: Check NOSTR signatures on relay messages (see message-integrity.md)
2. **Rate limiting**: Prevent flooding attacks
3. **Storage limits**: Enforce disk space quotas
4. **TTL enforcement**: Respect message expiration times

## Implementation Guidelines

### Android App

**Scanning**:
```java
BluetoothLeScanner scanner = bluetoothAdapter.getBluetoothLeScanner();
ScanSettings settings = new ScanSettings.Builder()
    .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
    .build();

List<ScanFilter> filters = Arrays.asList(
    new ScanFilter.Builder()
        .setServiceUuid(new ParcelUuid(UUID.fromString("0000FFF0-0000-1000-8000-00805F9B34FB")))
        .build()
);

scanner.startScan(filters, settings, scanCallback);
```

**Parsing service data**:
```java
@Override
public void onScanResult(int callbackType, ScanResult result) {
    ScanRecord record = result.getScanRecord();
    if (record == null) return;

    byte[] serviceData = record.getServiceData(
        new ParcelUuid(UUID.fromString("0000FFF0-0000-1000-8000-00805F9B34FB"))
    );

    if (serviceData != null && serviceData.length > 0) {
        String message = new String(serviceData, StandardCharsets.UTF_8);
        if (message.startsWith(">")) {
            // Process message
        }
    }
}
```

### T-Dongle ESP32-S3

**Initialization**:
```cpp
#include "ble/ble.h"

void setup() {
    ble_init("GEOGRAM-TDONGLE");
    ble_start_listening(true);  // wantsDuplicates = true for better reception
    ble_subscribe(my_event_handler, nullptr);
}

void loop() {
    ble_tick();  // Process event queue
}

void my_event_handler(const BleEvent* evt, void* ctx) {
    if (evt->type == BLE_EVT_MESSAGE_DONE) {
        Serial.print("Message completed: ");
        Serial.println(evt->data.done.snippet);
    }
}
```

---

**Version**: 1.0
**Last Updated**: 2025-11-09
**Compatibility**: Geogram Android app, T-Dongle ESP32-S3 firmware
