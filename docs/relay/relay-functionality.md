# Geogram Relay Functionality

## Overview

The Geogram Relay is a message synchronization and forwarding system that enables devices to temporarily carry and distribute messages via Bluetooth, creating a mesh network for message delivery in environments with limited or no internet connectivity.

## Core Concepts

### Relay as Temporary Message Carrier

A relay-enabled device acts as a temporary carrier for messages, holding them until:
- The message expires (configurable expiration time)
- The destination user personally requests deletion
- Storage limits are reached

### Message Structure

Relay messages use the same markdown format structure as group messages, enabling:
- Rich text formatting
- Message threading and incremental updates
- Extensible data fields

## Message Data Fields

Messages can contain additional data fields including:

- **User location coordinates**: Expected location of the user
- **Delivery coordinates**: Location information for relay handoff points
- **Timestamp metadata**: Creation, relay, and delivery times
- **Priority levels**: Urgent, normal, low priority
- **Expiration rules**: Time-to-live (TTL) and expiry conditions
- **Routing hints**: Preferred relay paths or geographic zones

## Message Distribution & Routing

### Multi-Copy Distribution

To increase delivery probability:
1. A relay message can create and distribute **multiple copies**
2. Each relay carrier attempts independent delivery
3. Redundant copies increase the chance at least one reaches destination
4. Duplicates are deduplicated at the destination based on message ID

### Relay Chain

Messages flow through a chain of relay nodes:

```
Sender → Relay A → Relay B → Relay C → Destination
```

Each relay in the chain:
- Stores the message temporarily
- Broadcasts availability to nearby devices
- Transfers message to other relays or the final recipient
- Tracks message propagation via metadata

### Store-and-Forward Mechanism

1. **Store**: Message saved to local relay storage (limited by disk space setting)
2. **Forward**: When another relay or destination comes into Bluetooth range:
   - Check if recipient needs this message
   - Transfer if appropriate
   - Update message metadata with relay hop information

## Delivery & Read Receipts

### Optional Receipt System

Senders can request two types of receipts:

#### 1. Delivery Receipt
- Generated when message reaches the destination device
- Contains:
  - Delivery timestamp
  - Final relay node ID
  - Path traversed (list of relay nodes)
  - Geographic coordinates (if available)

#### 2. Read Receipt
- Generated when recipient opens/reads the message
- Contains:
  - Read timestamp
  - User acknowledgment
  - Optional reply preview

### Receipt Routing

Receipts follow a reverse path back to the original sender:

```
Sender ← Relay C ← Relay B ← Relay A ← Destination
        (delivery receipt)
```

The receipt message includes:
- Complete relay path taken by the original message
- Timestamps at each relay hop
- Delivery confirmation and read status
- Return path taken by the receipt itself

This allows the sender to:
- Verify message delivery
- Track message routing efficiency
- Receive responses from the destination

## Bluetooth Synchronization

### Automatic Relay Discovery

When relay is enabled:
1. Device periodically advertises relay capability via BLE beacon
2. Nearby relay-enabled devices discover each other
3. Handshake protocol establishes secure connection
4. Message synchronization begins

### Sync Protocol

1. **Inventory Exchange**: Devices share list of message IDs they're carrying
2. **Gap Analysis**: Each device identifies messages it's missing
3. **Priority Transfer**: High-priority and fresh messages transferred first
4. **Deduplication**: Identical message IDs are not re-transferred
5. **Storage Management**: Oldest/expired messages purged to make space

### Data Transfer

- Uses Bluetooth file transfer or custom protocol
- Compressed message batches for efficiency
- Checksums verify data integrity
- Partial resume supported for interrupted transfers

## Storage Management

### Disk Space Allocation

Configurable storage limits (100MB to 10GB):
- Protects device from storage exhaustion
- Adjustable based on device capabilities
- Warning thresholds at 80% and 95% capacity

### Message Expiration

Messages automatically expire based on:
- **Time-to-Live (TTL)**: Sender-defined expiration time
- **Hop Count Limit**: Maximum relay chain length
- **Geographic Distance**: Auto-expire if relay moves too far from delivery zone
- **User Deletion**: Destination user can request deletion across all relays

### Garbage Collection

Relay periodically cleans up:
- Expired messages (past TTL)
- Delivered messages (with confirmed receipt)
- Low-priority messages when storage is full
- Duplicate messages (same ID, different relay paths)

## Auto-Accept Settings

### Message Filtering

Users can configure which messages to auto-accept:

1. **Only Text**: Plain text messages only (no attachments)
2. **Text and Images**: Text + image attachments
3. **Everything**: All message types (text, images, files, location data)

### Security Considerations

- Relay should validate message signatures
- Reject malformed or malicious content
- Rate limiting to prevent spam/flooding
- Optional whitelist/blacklist of relay nodes

## Use Cases

### 1. Message Delivery in Remote Areas
- Hikers carry messages between camps
- Rural areas with no cellular coverage
- Disaster zones with damaged infrastructure

### 2. Event Communication
- Festival attendees relay messages
- Conference participants share information
- Crowded areas where cellular is overloaded

### 3. Privacy-Focused Communication
- No internet dependency
- No central server logging
- Encrypted end-to-end with relay just forwarding

### 4. Offline Group Coordination
- Team members sync messages when they meet
- Gradual message propagation through a community
- No single point of failure

## Technical Architecture

### Message Format

Relay messages use the same format as chat messages for consistency:

```markdown
# Relay Message Group

> 2025-11-09 21:00_00 -- ALICE-K5XYZ
Message content in markdown format.
Can span multiple lines.

--> to: BOB-W6ABC
--> id: d4f2a8b1c3e5f7a9b2d4e6f8a0c2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4f6a8
--> type: private
--> ttl: 604800
--> priority: normal
--> relay-path: [relay-a, relay-b, relay-c]
--> receipts-requested: true
--> location: 40.7128,-74.0060
--> delivery-zone: 40.71,-74.00,5km
--> signature: a7f3b9e1d2c4f6a8b0e2d4f6a8c0b2e4f6a8b0c2e4f6a8b0c2e4f6a8b0c2e4
```

**Format Elements**:
- `> YYYY-MM-DD HH:MM_SS -- AUTHOR` - Message header with timestamp and author
- Message content follows (can be multi-line markdown)
- `-->` prefix - Metadata fields
- Blank line separates messages in a group

### Storage Structure

```
relay-storage/
├── messages/
│   ├── pending/           # Messages awaiting delivery
│   ├── delivered/         # Delivered but awaiting receipt
│   └── expired/           # Expired, pending cleanup
├── receipts/
│   ├── outbound/          # Receipts to send back to sender
│   └── inbound/           # Receipts received for sent messages
└── metadata/
    ├── relay-index.db     # Message index and routing info
    └── sync-state.db      # Sync state with other relays
```

## Future Enhancements

### Opportunistic Routing
- AI-based relay path prediction
- Learning common movement patterns
- Prioritizing messages likely to be delivered soon

### Mesh Intelligence
- Network topology awareness
- Relay node reputation scoring
- Dynamic message replication based on network density

### Advanced Receipts
- Multi-path delivery confirmation
- Partial delivery status (message received by relay but not destination)
- Relay health/status reports

### Encryption & Privacy
- End-to-end encryption between sender and recipient
- Relay nodes cannot read message content
- Onion routing for path privacy

## Implementation Considerations

### Android Platform
- Background service for relay operation
- Battery optimization exemptions
- Notification for relay activity
- Storage permission management

### Network Efficiency
- Bluetooth Low Energy for discovery
- Bluetooth Classic for bulk transfer
- Batch multiple messages in single transfer
- Compression for large message sets

### User Experience
- Visual indicator when relay is active
- Statistics: messages relayed, storage used
- Manual message management (delete, prioritize)
- Relay network map showing nearby nodes

---

**Status**: Design document
**Version**: 1.0
**Last Updated**: 2025-11-09
