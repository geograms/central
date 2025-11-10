# Geogram Protocol Bridges

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Design

---

## Overview

Geogram bridges connect the Geogram ecosystem to other communication protocols and mesh networks, enabling interoperability and extending the reach of offline-first messaging.

Each bridge acts as a **protocol translator** and **message relay**, converting between Geogram's format and external protocols while preserving message integrity and user identity.

---

## Bridge Architecture

### Common Components

All Geogram bridges share these architectural elements:

```
External Protocol Network
         ↕
   Protocol Gateway
         ↕
   Message Translator
         ↕
   Identity Mapper
         ↕
   Geogram Network
```

### Bridge Types

1. **Client Bridge (Android App)**
   - Runs on user's device
   - Direct connection to external protocol
   - User-controlled
   - Works offline with local relay
   - Example: Android MQTT client

2. **Server Bridge (geogram-server)**
   - Persistent 24/7 connection
   - Community-wide service
   - Centralized gateway
   - Historical archive
   - Example: Server-side MQTT relay

3. **Hardware Bridge (Dedicated Device)**
   - Standalone gateway device
   - Dual radio systems
   - Low power operation
   - Example: ESP32 with LoRa + BLE

---

## Message Translation Principles

### 1. Preserve Message Content
- Text content must be accurately translated
- Metadata preserved in Geogram format fields
- Original message ID tracked for deduplication

### 2. Identity Mapping
- External identities mapped to Geogram callsigns
- Consistent mapping (same external ID → same Geogram callsign)
- Bidirectional lookup table

### 3. Timestamp Preservation
- Original timestamp preserved
- Translation timestamp added as metadata
- Time zone handling

### 4. Rate Limiting
- Respect external protocol rate limits
- Queue messages when necessary
- Inform user of delays

### 5. Size Constraints
- Handle maximum payload size differences
- Truncate or split messages as needed
- Indicate truncation to user

---

## Implemented Bridges

| Bridge | Status | Type | Documentation |
|--------|--------|------|---------------|
| **Meshtastic MQTT** | Design | Client + Server | [meshtastic-bridge.md](meshtastic-bridge.md) |
| APRS-IS | Planned | Server | - |
| LoRaWAN | Planned | Hardware | - |
| Briar | Planned | Client | - |

---

## Security Considerations

### Encryption Boundaries

Each bridge creates an **encryption boundary**:

- **Geogram Side**: NOSTR signatures, optional end-to-end encryption
- **External Side**: External protocol's encryption (if any)
- **Bridge**: Decrypts external → Re-encrypts for Geogram

### Trust Model

- Bridge has access to plaintext messages
- Users must trust bridge operator (for server bridges)
- Client bridges run locally (user controls)

### Authentication

- Bridge authenticates to external protocol
- Bridge identity known to Geogram network
- Messages tagged with bridge source

---

## Development Guidelines

### Creating a New Bridge

1. **Document the external protocol**
   - Message format
   - Addressing scheme
   - Rate limits
   - Authentication method

2. **Design identity mapping**
   - How to convert external IDs to Geogram callsigns
   - Store mapping database

3. **Define message translation**
   - External format → Geogram markdown
   - Geogram markdown → External format
   - Handle special message types (location, media, etc.)

4. **Implement rate limiting**
   - Respect external protocol constraints
   - Queue management
   - User feedback

5. **Add configuration UI**
   - Settings for connection parameters
   - Authentication credentials
   - Enable/disable toggle

6. **Test interoperability**
   - Send message from Geogram → External
   - Receive message from External → Geogram
   - Round-trip verification

### Documentation Template

Use this structure for new bridge documentation:

```markdown
# [Protocol Name] Bridge

## Overview
[Brief description of the external protocol]

## Architecture
[Bridge type and deployment model]

## Message Translation
[Format conversion details]

## Identity Mapping
[How identities are mapped]

## Implementation
[Code structure and key files]

## Configuration
[User settings and setup]

## Testing
[How to test the bridge]
```

---

## Future Bridge Candidates

### APRS-IS (Automatic Packet Reporting System)
- Amateur radio digital communication
- Internet gateway via APRS-IS servers
- Position reports, messages, telemetry
- **Use Case**: Bridge ham radio operators to Geogram

### LoRaWAN
- Long Range Wide Area Network
- Gateway-based architecture
- Good for IoT sensors and tracking
- **Use Case**: Connect LoRaWAN devices to Geogram

### Briar
- Peer-to-peer messaging app
- Bluetooth and Tor transport
- Focus on censorship resistance
- **Use Case**: Bridge Briar users to Geogram mesh

### XMPP/Jabber
- Federated instant messaging protocol
- Widely deployed in privacy communities
- Extensible protocol
- **Use Case**: Connect XMPP servers to Geogram

### Delta Chat
- Email-based messaging
- Uses existing email infrastructure
- Decentralized by nature
- **Use Case**: Bridge email users to Geogram

### Matrix Protocol
- Federated real-time communication
- Bridge-friendly design
- Rich media support
- **Use Case**: Connect Matrix rooms to Geogram groups

---

## Performance Considerations

### Bandwidth Usage

Bridges must account for different bandwidth characteristics:

| Protocol | Typical Bandwidth | Latency | Message Size |
|----------|------------------|---------|--------------|
| Geogram BLE | ~100-1000 kbps | 10-100ms | Up to 10KB |
| Meshtastic LoRa | ~0.3-5 kbps | 1-10s | 237 bytes |
| APRS | ~1.2 kbps | 1-60s | 256 bytes |
| XMPP | Internet speed | <1s | Large |

### Latency Impact

- Message delays vary by protocol
- Queue depth can grow
- User expectations management
- Status indicators in UI

### Resource Consumption

- MQTT connections (persistent TCP)
- Protocol buffer encoding/decoding
- Database storage for mapping tables
- Battery impact (for mobile bridges)

---

## Testing Bridges

### Unit Tests
- Message translation (external → Geogram)
- Message translation (Geogram → external)
- Identity mapping (bidirectional)
- Rate limiting

### Integration Tests
- Connect to test server/network
- Send/receive real messages
- Verify round-trip integrity
- Handle connection failures

### Field Tests
- Deploy to real users
- Monitor message success rate
- Measure latency
- Gather user feedback

---

## Monitoring & Diagnostics

### Metrics to Track

- **Messages translated**: Count by direction
- **Translation errors**: Failed conversions
- **Queue depth**: Pending outbound messages
- **Latency**: Time from receive to deliver
- **Identity cache**: Number of mapped identities

### Debug Logging

Bridge should log:
- Connection status
- Message received (summary)
- Translation result
- Delivery status
- Errors with details

### User Feedback

Show in UI:
- Bridge connection status (connected/disconnected)
- Message queue depth
- Last message timestamp
- Error notifications

---

## Contribution Guidelines

Want to implement a new bridge? Follow these steps:

1. **Discuss in GitHub Discussions**
   - Propose the bridge
   - Explain use case
   - Get community feedback

2. **Create Design Document**
   - Follow template above
   - Include protocol details
   - Design identity mapping

3. **Implement Proof of Concept**
   - Basic message translation
   - Test with real protocol
   - Demonstrate feasibility

4. **Develop Full Implementation**
   - Complete message translation
   - Add configuration UI
   - Write tests
   - Document setup

5. **Submit Pull Request**
   - Include documentation
   - Add to this README
   - Provide test instructions

---

## Related Documentation

- **[Relay Protocol](../relay/relay-protocol.md)** - Geogram message format
- **[Message Integrity](../relay/message-integrity.md)** - Signatures and verification
- **[BLE Protocol](../relay/message-ble.md)** - Bluetooth mesh networking

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors
