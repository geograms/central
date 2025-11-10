# Geogram Documentation

Welcome to the Geogram documentation. This directory contains comprehensive technical documentation for the entire Geogram ecosystem.

---

## 📑 Table of Contents

- [Getting Started](#getting-started)
- [System Architecture](#system-architecture)
- [Protocols & Specifications](#protocols--specifications)
- [Implementation Details](#implementation-details)
- [Development](#development)

---

## 🚀 Getting Started

New to Geogram? Start here:

1. **[Main README](../README.md)** - Project overview and quick start
2. **[Development Guide](development/claude-code-guide.md)** - Setup instructions for all platforms
3. **[Relay Functionality Overview](relay/README.md)** - Understand how relay messaging works

---

## 🏗️ System Architecture

### Core Components

Geogram consists of several interconnected components:

```
┌──────────────────────────────────────────────────────────────┐
│                     Geogram Ecosystem                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Mobile    │  │     Web     │  │   Server    │         │
│  │   Android   │  │   Browser   │  │    Java     │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                  │
│         └────────────────┴────────────────┘                  │
│                       │                                       │
│         ┌─────────────┴─────────────┐                       │
│         │                           │                        │
│  ┌──────▼──────┐           ┌────────▼────────┐             │
│  │  BLE Mesh   │           │  NOSTR Network  │             │
│  │  (T-Dongle) │           │   (Internet)    │             │
│  └─────────────┘           └─────────────────┘             │
│         │                                                    │
│  ┌──────▼──────┐                                            │
│  │  Radio/APRS │                                            │
│  │   (UV-K5)   │                                            │
│  └─────────────┘                                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Communication Layers

1. **Physical Layer**: Radio (FM/APRS), Bluetooth Low Energy
2. **Protocol Layer**: NOSTR, APRS-IS, Custom BLE protocol
3. **Application Layer**: Messaging, location sharing, relay routing
4. **Storage Layer**: SQLite (Android), IndexedDB (Web), File-based (Server)

---

## 📡 Protocols & Specifications

### Relay System

The relay system enables store-and-forward message delivery through a mesh of mobile devices:

- **[Relay System Overview](relay/README.md)** - High-level explanation
- **[Relay Functionality](relay/relay-functionality.md)** - Detailed functionality specification
- **[Relay Protocol](relay/relay-protocol.md)** - Message format and storage (v1.2)
- **[Message Integrity](relay/message-integrity.md)** - Cryptographic verification (v1.1)
- **[BLE Protocol](relay/message-ble.md)** - Bluetooth message protocol (v1.0)

### Key Concepts

#### Message Format
Messages use markdown format with YAML frontmatter:
```markdown
---
id: message-id-hash
from: sender-callsign
to: recipient-callsign
timestamp: 2025-11-09T21:00:00Z
---

Message content here...
```

#### Geographic Grid System
Uses GeoCode4 (base-36, 8-character codes) for location targeting:
- Example: `RY1A-IUZS` represents a specific geographic grid
- Enables geographic message filtering and routing

#### NACK (Negative Acknowledgment)
BLE protocol includes packet loss recovery:
- Detects missing message parcels
- Requests retransmission with `/repeat [parcel-id]`
- Archives sent messages for retransmission

---

## 🔧 Implementation Details

### Platform-Specific Implementations

#### Android
- **[NACK Implementation](implementation/android-nack-implementation.md)** - BLE packet loss recovery
- Language: Java 17
- Database: Room (SQLite)
- BLE: Google Nearby API
- Min SDK: 29 (Android 10)

#### Web/HTML
- Language: Vanilla JavaScript (ES6+)
- Storage: localStorage + IndexedDB
- No build step required
- Progressive Web App capabilities

#### Server
- Language: Java 21
- Build: Maven with shade plugin
- NOSTR: nostr-java library
- ACME: Automatic HTTPS certificates

#### UV-K5 Firmware
- Language: C
- Architecture: ARM Cortex-M0
- Audio encoding: Custom Geogram protocol
- Flash: Limited space, feature flags control size

#### ESP32 Beacons
- Language: C++
- Framework: Arduino (PlatformIO)
- Function: BLE advertising and presence detection
- Board: LilyGO T-Dongle S3 (ESP32-S3)

---

## 💻 Development

### Development Tools

- **[Claude Code Guide](development/claude-code-guide.md)** - Complete setup and build instructions
  - Repository structure
  - Build commands for all platforms
  - Architecture notes
  - Integration points

### Build Requirements

| Platform | Requirements |
|----------|--------------|
| Android | Android Studio, Java 17, Gradle |
| Web | Modern browser (no build needed) |
| Server | Java 21, Maven |
| UV-K5 | arm-none-eabi-gcc or Docker |
| ESP32 | PlatformIO |

### Testing

- **Android**: JUnit tests (`./gradlew test`)
- **Server**: JUnit Jupiter (`mvn test`)
- **Firmware**: Manual testing on hardware
- **Web**: Manual browser testing

---

## 📊 Documentation Status

| Document | Version | Last Updated | Status |
|----------|---------|--------------|--------|
| Relay Functionality | 1.0 | 2025-11-09 | Design |
| Relay Protocol | 1.2 | 2025-11-09 | Design |
| Message Integrity | 1.1 | 2025-11-09 | Design |
| BLE Protocol | 1.0 | 2025-11-09 | Design |
| Android NACK | 1.0 | 2025-11-09 | Complete |

---

## 🤝 Contributing to Documentation

Documentation improvements are welcome! To contribute:

1. **Identify gaps**: Missing information or unclear sections
2. **Create/update docs**: Follow existing markdown format
3. **Submit PR**: To the central repository
4. **Link properly**: Update this index and README.md

### Documentation Standards

- Use markdown format
- Include version and last updated date
- Add diagrams where helpful (ASCII art or mermaid)
- Link between related documents
- Keep technical accuracy high
- Provide code examples

---

## 🔍 Quick Reference

### Common Tasks

- **Find BLE protocol details**: [BLE Protocol](relay/message-ble.md)
- **Understand message signing**: [Message Integrity](relay/message-integrity.md)
- **Build Android app**: [Claude Code Guide](development/claude-code-guide.md#geogram-android-android-app)
- **Set up relay**: [Relay Functionality](relay/relay-functionality.md)
- **Message format**: [Relay Protocol](relay/relay-protocol.md#message-format)

### External Resources

- **NOSTR Protocol**: [nostr.com](https://nostr.com)
- **APRS**: [aprs.org](http://www.aprs.org)
- **UV-K5 Wiki**: [github.com/ludwich66/Quansheng_UV-K5_Wiki](https://github.com/ludwich66/Quansheng_UV-K5_Wiki)
- **GeoCode4**: See [geogram-android GeoCode4.java](../geogram-android/app/src/main/java/offgrid/geogram/util/GeoCode4.java)

---

**Last Updated**: 2025-11-10
