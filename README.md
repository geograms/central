# Geogram Central

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-latest-brightgreen.svg)](docs/)

> **Resilient, Decentralized Communication for the Modern World**

Geogram is a comprehensive offline-first communication ecosystem designed for environments with limited or no internet connectivity. It integrates radio communications (APRS/FM), BLE beacons, NOSTR-based messaging, and hybrid online/offline mobile apps to enable proximity-based and radio-aware communication without internet dependency.

---

## 🌟 Overview

Geogram enables communication through multiple complementary channels:

- **📡 Radio (APRS/FM)**: Long-range voice and data transmission using amateur radio
- **📲 Bluetooth Low Energy**: Short-range mesh networking between nearby devices
- **🌐 NOSTR Protocol**: Decentralized, censorship-resistant messaging when internet is available
- **💼 Relay System**: Store-and-forward message delivery carried by mobile users
- **📦 Collections System**: Text-based content management for forums, blogs, events, places, and more

### Key Features

- ✅ **Offline-First Design**: Core functionality works without internet
- ✅ **Multi-Platform**: Android, Web browser, ESP32 firmware, and radio hardware
- ✅ **Mesh Networking**: Automatic relay through nearby devices via BLE
- ✅ **End-to-End Encryption**: Messages secured with NOSTR cryptography (Schnorr signatures)
- ✅ **Geographic Routing**: Grid-based message delivery targeting specific locations
- ✅ **Interoperability**: Compatible with existing APRS infrastructure

---

## 📚 Documentation

### Getting Started

- **[Documentation Index](docs/README.md)** - Complete documentation overview
- **[Development Guide](docs/development/claude-code-guide.md)** - Setup and build instructions for all platforms

### Collections System

Geogram Collections provide a text-based, P2P-ready content management system for offline-first scenarios:

- **[Collections Overview](docs/collections/others/README.md)** - Introduction to the collections system
- **[User Guide](docs/collections/others/user-guide.md)** - How to create and use collections
- **[Architecture](docs/collections/others/architecture.md)** - System design and technical overview
- **[API Reference](docs/collections/others/api-reference.md)** - Complete API documentation
- **[Security Model](docs/collections/others/security-model.md)** - Cryptographic verification and permissions

#### Collection Types

Geogram supports various collection types for different content needs:

| Type | Description | Specification |
|------|-------------|---------------|
| **Places** | Geographic locations with photos, coordinates, and radius | [places-format-specification.md](docs/collections/types/places-format-specification.md) |
| **Events** | Time-based gatherings with photos, location, and reactions | [events-format-specification.md](docs/collections/types/events-format-specification.md) |
| **Postcards** | Sneakernet messages with cryptographic stamps and delivery receipts | [postcards-format-specification.md](docs/collections/types/postcards-format-specification.md) |
| **Forum** | Discussion threads with posts and replies | [forum-format-specification.md](docs/collections/types/forum-format-specification.md) |
| **Blog** | Articles and blog posts with comments | [blog-format-specification.md](docs/collections/types/blog-format-specification.md) |
| **Chat** | Real-time messaging with channels | [chat-format-specification.md](docs/collections/types/chat-format-specification.md) |
| **News** | News articles with categories and reactions | [news-format-specification.md](docs/collections/types/news-format-specification.md) |

### Privacy & Security

- **[Permissions Explained](docs/privacy/permissions-explained.md)** - Comprehensive transparency about Android app permissions, exactly how they're used, and links to source code for verification

### Protocol Bridges

- **[Bridges Overview](docs/bridges/README.md)** - Interoperability with other communication networks
- **[Meshtastic Bridge](docs/bridges/meshtastic-bridge.md)** - Connect Geogram to LoRa mesh networks via MQTT

### Architecture & Protocols

#### Relay System
- **[Relay Functionality](docs/relay/relay-functionality.md)** - How relay message delivery works
- **[Relay Protocol](docs/relay/relay-protocol.md)** - Message format, storage, and routing specification
- **[Message Integrity](docs/relay/message-integrity.md)** - Cryptographic verification and lifecycle
- **[BLE Protocol](docs/relay/message-ble.md)** - Low-level Bluetooth message protocol

#### Connection Protocols
- **[BLE GATT Findings](docs/connections/BLE_GATT_FINDINGS.md)** - Bluetooth Low Energy protocol details
- **[Bluetooth Flow Control](docs/connections/BLUETOOTH_FLOW_CONTROL_FIX.md)** - Flow control implementation
- **[Chunked Downloads](docs/connections/CHUNKED_DOWNLOADS_IMPLEMENTATION.md)** - Large file transfer over BLE

#### Implementation Details
- **[Android NACK Implementation](docs/implementation/android-nack-implementation.md)** - BLE packet loss recovery system

---

## 🚀 Repositories

Geogram is a monorepo containing multiple interconnected sub-projects, each maintained in its own repository:

### Mobile & Web Applications

| Repository | Description | Tech Stack |
|------------|-------------|------------|
| **[geogram-android](geogram-android/)** | Android mobile app | Java, Room DB, Google Nearby API |
| **[geogram-html](geogram-html/)** | Browser-based client | Vanilla JavaScript (ES6+), No build required |

### Backend & Server

| Repository | Description | Tech Stack |
|------------|-------------|------------|
| **[geogram-server](geogram-server/)** | Java backend server | Java 21, Maven, NOSTR-java |

### Hardware & Firmware

| Repository | Description | Tech Stack |
|------------|-------------|------------|
| **[geogram-k5](geogram-k5/)** | UV-K5 radio firmware | C, ARM Cortex-M0 |
| **[geogram-tdongle](geogram-tdongle/)** | ESP32-S3 BLE beacon (LilyGO T-Dongle S3) | C++, PlatformIO, Arduino |
| **[geogram-esp32](geogram-esp32/)** | ESP32 experimental boards | C++, PlatformIO |
| **[geogram-wta1](geogram-wta1/)** | ESP32 WTA1 variant | C++, PlatformIO |

---

## 🛠️ Quick Start

### Prerequisites

Choose based on what you want to build:

- **Android App**: Android Studio, Java 17
- **Web App**: Modern web browser (no build needed)
- **Server**: Java 21, Maven
- **K5 Firmware**: arm-none-eabi-gcc or Docker
- **ESP32 Firmware**: PlatformIO

### Building Projects

Each subproject has its own build system. See the [Development Guide](docs/development/claude-code-guide.md) for detailed instructions.

**Quick examples:**

```bash
# Android App
cd geogram-android
./gradlew assembleDebug

# Java Server
cd geogram-server
mvn clean package

# UV-K5 Firmware
cd geogram-k5
make  # or: sudo ./compile-with-docker.sh

# ESP32 Beacon
cd geogram-tdongle
pio run --target upload
```

---

## 🔧 Use Cases

### 1. Remote Area Communication
- Hikers, campers, and backcountry users carrying messages between locations
- Rural areas with no cellular coverage
- Mountain rescue coordination

### 2. Disaster & Emergency Response
- Communication when infrastructure is damaged
- Decentralized message distribution without servers
- Multi-hop relay through volunteers

### 3. Privacy-Focused Messaging
- No internet dependency = no server logging
- End-to-end encryption via NOSTR
- Local-first communication

### 4. Event & Festival Communication
- Conference attendees sharing information
- Festival coordination without overloaded cellular
- Community mesh networking

### 5. Amateur Radio Integration
- APRS-compatible message forwarding
- Radio-to-smartphone bridging
- Voice and data integration

---

## 🤝 Contributing

We welcome contributions! Each subproject maintains its own contribution guidelines:

- **Bug Reports**: Open issues in the relevant subproject repository
- **Feature Requests**: Discuss in issues before implementing
- **Pull Requests**: Follow the project's coding standards
- **Documentation**: Help improve docs in this central repository

---

## 📖 Technical Details

### Communication Flow

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Radio     │ FM/APRS │   Android   │   BLE   │   Android   │
│   UV-K5     │◄───────►│   Device A  │◄───────►│   Device B  │
└─────────────┘         └─────────────┘         └─────────────┘
                              │                         │
                              │ Internet (optional)     │
                              ▼                         ▼
                        ┌──────────────────────────────┐
                        │     NOSTR Relays             │
                        │  (Decentralized Network)     │
                        └──────────────────────────────┘
```

### Data Storage

- **Android**: Room database (SQLite) + local key storage
- **Web**: localStorage + IndexedDB (no backend required)
- **Server**: File-based configuration + ACME certificates
- **Relay Messages**: Individual .md files with human-readable naming

### Cryptography

- **NOSTR Keys**: secp256k1 (Schnorr signatures)
- **Message IDs**: SHA-256 hash of event data
- **Signatures**: Sign with sender's nsec (private key)
- **Verification**: Validate with npub (public key)

---

## 📄 License

Copyright 2025 Geogram Contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## 🌐 Links

- **GitHub Organization**: [github.com/geograms](https://github.com/geograms)
- **Central Repository**: [github.com/geograms/central](https://github.com/geograms/central)
- **Issue Tracker**: [Report issues](https://github.com/geograms/central/issues)
- **Discussions**: [Community discussions](https://github.com/geograms/central/discussions)

---

## 📮 Contact

- **Project Maintainer**: [Your name/contact]
- **Community**: [Discord/Matrix/Forum link]
- **Email**: [Contact email]

---

**Built with ❤️ for resilient, decentralized communication**
