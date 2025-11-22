# Geogram Relay System

The Geogram Relay System enables **store-and-forward message delivery** through a mesh network of mobile devices, providing resilient communication in environments with limited or no internet connectivity.

---

## 📖 Overview

### What is a Relay?

A relay is a **mobile device that temporarily carries messages** and delivers them to other devices via Bluetooth Low Energy (BLE) when they come within range. Think of it as a digital postman who physically carries messages between locations.

### How It Works

```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│  Alice   │   BLE   │  Relay A │  moves  │  Relay B │   BLE   │   Bob    │
│  Sender  │────────►│  Carries │────────►│  Carries │────────►│ Receiver │
└──────────┘         └──────────┘         └──────────┘         └──────────┘
  Location X           Location X→Y         Location Y           Location Y
```

1. **Alice** sends a message at Location X
2. **Relay A** receives it via BLE and stores it
3. **Relay A** physically moves to Location Y
4. **Relay B** receives it from Relay A via BLE
5. **Bob** receives it from Relay B at Location Y

---

## 🎯 Key Features

### Offline-First Design
- ✅ No internet required for core functionality
- ✅ Messages stored locally on relay devices
- ✅ Automatic synchronization when devices meet
- ✅ Works in remote areas, disaster zones, or events

### Multi-Copy Distribution
- ✅ Messages can be carried by multiple relays simultaneously
- ✅ Increases delivery probability
- ✅ Automatic deduplication at destination
- ✅ Redundancy ensures at least one copy arrives

### Geographic Routing
- ✅ Messages tagged with destination grid coordinates
- ✅ Relays can filter by geographic area
- ✅ Reduces unnecessary message storage
- ✅ Enables location-aware delivery

### Paid Delivery (Optional)
- ✅ Senders can offer payment for delivery
- ✅ Multiple payment methods supported
- ✅ Delivery receipt proves successful delivery
- ✅ Incentivizes long-distance relay carriers

---

## 📚 Documentation

### Core Documents

1. **[Relay Functionality](relay-functionality.md)** - High-level functionality overview
   - Relay as temporary message carrier
   - Message distribution and routing
   - Storage management
   - Use cases

2. **[Relay Protocol](relay-protocol.md)** - Technical specification (v1.2)
   - Message format (markdown with YAML frontmatter)
   - Message types (private, broadcast, emergency, etc.)
   - Storage structure (individual .md files)
   - Payment protocol
   - Relay message selection criteria

3. **[Message Integrity](message-integrity.md)** - Security and verification (v1.1)
   - NOSTR-based cryptographic signatures
   - Message ID generation (SHA-256)
   - Relay chain tracking
   - Deletion requests
   - BLE protocol integrity (CRC8, CRC32, NACK)

4. **[BLE Protocol](message-ble.md)** - Low-level Bluetooth protocol (v1.0)
   - BLE service UUID and advertising
   - Single-packet commands (≤20 bytes)
   - Multi-packet protocol (header + data)
   - NACK retransmission
   - Deduplication
   - Event bus integration

---

## 🔧 Technical Architecture

### Message Lifecycle

```
1. Creation      → Message created with NOSTR signature
2. Transmission  → Sent via BLE to nearby relay
3. Storage       → Stored as .md file on relay device
4. Relay Hops    → Forwarded through multiple relays
5. Delivery      → Received by destination device
6. Receipt       → Optional delivery/read receipt sent back
7. Cleanup       → Expired or delivered messages deleted
```

### Message Format

Messages use **markdown format** with YAML frontmatter:

```markdown
---
id: d4f2a8b1c3e5f7a9b2d4e6f8a0c2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4f6a8
from: ALICE-K5XYZ
to: BOB-W6ABC
timestamp: 1699564801
ttl: 604800
priority: normal
relay-path: [RELAY-A, RELAY-B, RELAY-C]
receipts-requested: true
location: 40.7128,-74.0060
type: private
---

# Urgent: Meet at campsite

Bob, I'm heading to the campsite at grid RY1A-IUZS.
Should arrive by 3pm. Please confirm receipt.

## Attachments

attachment: photo.jpg
mime-type: image/jpeg
size: 245678
sha256: a7f3b9e1d2c4f6a8b0e2d4f6a8c0b2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4
data: [base64-encoded-image-data]
```

### Storage Structure

```
relay-storage/
├── messages/
│   ├── pending/
│   │   ├── ALICE-K5XYZ_2025-11-09_22-00_normal_a7c5b1.md
│   │   ├── CHARLIE_2025-11-09_21-30_urgent_f3d8a2.md
│   │   └── ...
│   ├── delivered/
│   │   └── BOB-W6ABC_2025-11-08_15-20_normal_b4e7c9.md
│   └── archived.zip
├── receipts/
│   ├── outbound/
│   └── inbound/
└── metadata/
    ├── relay-index.db
    └── sync-state.db
```

### BLE Protocol

**Single-Packet Commands** (≤20 bytes):
```
>+053156@RY1A-IUZS  (location message)
>/repeat AF2         (NACK request)
```

**Multi-Packet Messages**:
```
>AF0:SENDER:DEST:CHECKSUM  (header packet)
>AF1:First part of message (data packet 1)
>AF2:Second part of messag (data packet 2)
>AF3:e content here.       (data packet 3)
```

---

## 🚀 Use Cases

### 1. Remote Hiking & Camping
**Scenario**: Hikers in backcountry with no cell service

- Hikers leave messages at trailheads
- Other hikers carry messages between locations
- Messages delivered days later when hikers return
- Emergency messages prioritized

### 2. Disaster Response
**Scenario**: Earthquake damages cellular infrastructure

- First responders carry messages between zones
- Coordination without central infrastructure
- Multi-hop relay through volunteers
- Critical messages tagged as urgent

### 3. Festival/Event Communication
**Scenario**: Music festival with overloaded cellular

- Attendees share meetup locations
- BLE mesh network within venue
- No dependency on cellular towers
- Works when internet fails

### 4. Privacy-Focused Messaging
**Scenario**: Journalists or activists need secure comms

- No internet = no server logs
- End-to-end NOSTR encryption
- Physical relay through trusted carriers
- Message expiration prevents long-term storage

### 5. Rural Community Networks
**Scenario**: Village with no internet access

- Community members relay messages
- Gradual message propagation
- News and information sharing
- Optional payment for mail delivery

---

## ⚙️ Configuration

### Relay Settings

Users can configure:

1. **Storage Allocation** (100MB - 10GB)
   - Disk space dedicated to relay messages
   - Prevents device storage exhaustion

2. **Auto-Accept Filters**
   - Only text (no attachments)
   - Text and images
   - Everything (text, images, files, location)

3. **Message Selection Criteria**
   - Geographic filters (grid targets)
   - Message type filters
   - Priority filters (minimum threshold)
   - Size limits
   - Time range filters
   - Payment requirements

4. **Relay Duration**
   - Enable relay for specific time period
   - Automatic disable when storage full
   - Manual override available

---

## 🔐 Security & Privacy

### Message Integrity

- **NOSTR Signatures**: All messages signed with sender's private key (nsec)
- **Verification**: Recipients verify with public key (npub)
- **Message IDs**: SHA-256 hash prevents tampering
- **Relay Stamps**: Each relay adds signed timestamp with GPS coordinates

### Privacy Features

- **No Server Logging**: No central server = no logs
- **Encrypted Content**: End-to-end encryption (relay can't read)
- **Expiration**: Messages auto-delete after TTL expires
- **Deletion Requests**: Sender or recipient can request deletion

### Spam Protection

- **Rate Limiting**: Max 5000 messages per day per sender
- **Size Limits**: Max message size configurable
- **Priority Queues**: Urgent messages processed first
- **Checksum Verification**: CRC8/CRC32 prevents corruption

---

## 📊 Performance

### Delivery Probability

Multi-copy distribution increases delivery success:

| Relay Carriers | Single Failure Rate | Delivery Success |
|----------------|---------------------|------------------|
| 1              | 30%                 | 70%              |
| 2              | 30%                 | 91%              |
| 3              | 30%                 | 97%              |
| 5              | 30%                 | 99.8%            |

### Storage Efficiency

Example: 1GB relay storage can hold approximately:

- **5,000** text-only messages (200KB each)
- **500** messages with images (2MB each)
- **100** messages with video (10MB each)

### Battery Impact

BLE relay operation (per hour):
- **Scanning**: ~2% battery drain
- **Advertising**: ~1% battery drain
- **Data Transfer**: ~3-5% per 100 messages

---

## 🛠️ Implementation Status

### Completed

- ✅ Protocol specification (v1.2)
- ✅ Message format and storage design
- ✅ BLE protocol specification (v1.0)
- ✅ Android NACK implementation
- ✅ Cryptographic verification design

### In Progress

- 🔄 Android relay storage implementation
- 🔄 BLE message synchronization
- 🔄 Geographic routing algorithm
- 🔄 Payment receipt workflow

### Planned

- 📋 iOS relay support
- 📋 ESP32 standalone relay device
- 📋 Web-based relay management UI
- 📋 Relay network visualization

---

## 📖 Further Reading

- **[Main Documentation Index](../README.md)**
- **[Development Guide](../development/claude-code-guide.md)**
- **[Android NACK Implementation](../implementation/android-nack-implementation.md)**

---

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design & Early Implementation
