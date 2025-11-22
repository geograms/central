# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Geogram is a multi-platform offline-first communication ecosystem designed for resilient, decentralized messaging. It integrates radio communications (APRS/FM), BLE beacons, NOSTR-based messaging, and hybrid online/offline mobile apps to enable proximity-based and radio-aware communication without internet dependency.

## Repository Structure

This is a monorepo containing multiple interconnected sub-projects:

- **geogram-html**: Browser-based client (vanilla JS, no build required)
- **geogram-android**: Android app (Kotlin, Gradle)
- **geogram-server**: Java backend server (Maven)
- **geogram-k5**: Custom firmware for Quansheng UV-K5 radios (C, ARM Cortex-M0)
- **geogram-tdongle**: ESP32-S3 BLE beacon firmware (C++, PlatformIO)
- **geogram-esp32**: ESP32 experimental boards (Arduino/PlatformIO)
- **geogram-wta1**: Another ESP32 variant (PlatformIO)

## Build & Development Commands

### geogram-html (Browser App)
```bash
cd geogram-html
# No build needed - open index.html in browser
# Or serve locally:
python3 -m http.server 8000
```

### geogram-android (Android App)
```bash
cd geogram-android
./gradlew assembleDebug          # Build debug APK
./gradlew installDebug           # Build and install to connected device
./gradlew test                   # Run unit tests
./gradlew connectedAndroidTest   # Run instrumented tests
```
- **Min SDK**: 29 (Android 10)
- **Target SDK**: 34
- **Language**: Java 17
- **Package**: `offgrid.geogram`

### geogram-server (Java Backend)
```bash
cd geogram-server
mvn clean package               # Build shaded JAR
mvn test                        # Run tests
java -jar target/geogram-server-1.0.0.jar  # Run server
```
- **Java Version**: 21+ (required by nostr-java)
- **Main Class**: `geogram.Start`
- **Build Tool**: Maven with maven-shade-plugin
- Output: Single runnable JAR in `target/`

### geogram-k5 (UV-K5 Firmware)
```bash
cd geogram-k5

# Standard build (requires arm-none-eabi-gcc):
make clean
make

# Docker build (recommended for reproducible builds):
sudo ./compile-with-docker.sh

# Output: compiled-firmware/firmware.packed.bin
```
- **Architecture**: ARM Cortex-M0
- **Toolchain**: arm-none-eabi-gcc or Docker
- **Flash method**: Follow [UV-K5 Wiki](https://github.com/ludwich66/Quansheng_UV-K5_Wiki/wiki)
- **Configuration**: Edit Makefile feature flags (ENABLE_*)

### geogram-tdongle (ESP32-S3 Beacon)
```bash
cd geogram-tdongle
pio run --target upload         # Build and flash
pio device monitor -b 115200    # Serial monitor
```
- **Board**: esp32-s3-devkitc-1 (LilyGO T-Dongle S3)
- **Framework**: Arduino
- **Upload Speed**: 921600 baud

### geogram-wta1 (ESP32 Variant)
```bash
cd geogram-wta1
pio run --target upload
```

## Architecture Notes

### Communication Flow
1. **Radio Layer**: UV-K5 firmware transmits audio-encoded Geogram packets over FM
2. **BLE Layer**: T-Dongle beacons advertise presence; Android app detects and logs
3. **NOSTR Integration**: HTML app and Android app use NOSTR for decentralized, end-to-end encrypted messaging
4. **Server Bridge**: Java server acts as APRS gateway and NOSTR relay connector

### Key Integration Points
- **BLE Protocol**: Custom beacon format shared between T-Dongle firmware and Android app
- **Geogram Audio Protocol**: Proprietary encoding used by UV-K5 firmware for FM transmission
- **NOSTR Keys**: Generated client-side in HTML app and Android app; stored locally only
- **APRS Compatibility**: Server can relay to/from standard APRS-IS infrastructure

### Data Storage
- **HTML App**: localStorage + IndexedDB (no backend)
- **Android App**: Room database (SQLite) + local key storage
- **Server**: File-based (config.json, ACME certificates in acme/)

### Platform-Specific Notes

#### geogram-html
- Vanilla JavaScript (ES6+), no build step or dependencies
- Tab-based architecture: `tabs/` directory contains modular components
- Libraries in `lib/`: nostr.bundle.js, map libraries, morse code generator
- Fully offline-capable with service workers (if configured)

#### geogram-android
- BLE scanning requires ACCESS_FINE_LOCATION permission (Android requirement)
- Uses Google Nearby API for BLE Direct peer messaging
- BouncyCastle for cryptographic operations
- Room for local database persistence

#### geogram-k5
- Highly constrained environment: limited flash/RAM
- Feature flags in Makefile control binary size
- Custom bootloader; requires specific flashing tools
- `app/geogram.o` contains Geogram-specific protocol implementation

#### geogram-server
- Requires Java 21+ due to nostr-java dependency
- ACME client for Let's Encrypt (automatic HTTPS)
- JitPack repository used for nostr-java artifact
- Maven Shade creates fat JAR with all dependencies

## Testing

- **Android**: `./gradlew test` (unit), `./gradlew connectedAndroidTest` (instrumented)
- **Server**: `mvn test` (JUnit Jupiter)
- **K5 Firmware**: No automated tests; flash and verify on hardware
- **HTML App**: Manual testing in browser

## Development Environment

- **Required Tools**:
  - Java 21+ (for server)
  - Android Studio (for Android app)
  - PlatformIO (for ESP32 projects)
  - arm-none-eabi-gcc or Docker (for K5 firmware)
  - Modern browser (for HTML app)

- **Emscripten Environment**:
  - EMSDK is configured in the environment (visible in bash output)
  - Used for potential WebAssembly builds (not currently active in projects)

## Commit Preferences

- **Do NOT include Claude Code credits** in commit messages
- Commit messages should be clean and professional without AI attribution footers
