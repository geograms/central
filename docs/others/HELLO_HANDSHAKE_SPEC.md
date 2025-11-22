# Geogram Relay Hello Handshake - Full Specification

## Overview
Complete WebSocket "hello" handshake implementation with proper Nostr NIP-01 secp256k1 signatures between geogram-desktop (Flutter/Dart) and geogram-relay (Java).

## Implementation Status

### Completed
✓ Added dependencies to pubspec.yaml: web_socket_channel, crypto, pointycastle, hex
✓ Created basic NostrEvent structure in Dart
✓ Created implementation plan document

### In Progress
- Implementing proper secp256k1 signing in Dart
- Implementing proper secp256k1 verification in Java
- WebSocket service with hello handshake
- Relay server message handling
- UI integration with logging

## Technical Requirements

### Cryptography
- **Algorithm**: secp256k1 (Bitcoin/Nostr standard)
- **Hashing**: SHA-256
- **Signature Format**: Schnorr signatures (64 bytes)
- **Key Format**: 32-byte private key, 33/65-byte public key

### Flutter Dependencies
```yaml
web_socket_channel: ^3.0.1  # WebSocket client
crypto: ^3.0.6              # SHA-256 hashing
pointycastle: ^3.9.1        # secp256k1 crypto
hex: ^0.2.0                 # Hex encoding/decoding
```

### Java Dependencies (pom.xml)
```xml
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcprov-jdk18on</artifactId>
    <version>1.78.1</version>
</dependency>
```

## Files To Implement

### 1. Flutter: lib/util/bech32.dart (NEW)
Bech32 encoding/decoding for npub/nsec

### 2. Flutter: lib/util/nostr_crypto.dart (NEW)
secp256k1 signing and verification using pointycastle

### 3. Flutter: lib/util/nostr_event.dart (REWRITE)
Proper Nostr event with secp256k1 signatures

### 4. Flutter: lib/services/websocket_service.dart (NEW)
WebSocket management with hello handshake

### 5. Flutter: lib/services/relay_service.dart (MODIFY)
Add connection methods

### 6. Flutter: lib/pages/relays_page.dart (MODIFY)
Add connect button and status display

### 7. Java: NostrEvent.java (NEW)
Parse and verify Nostr events

### 8. Java: NostrCrypto.java (NEW)
secp256k1 verification using Bouncy Castle

### 9. Java: RelayServer.java (MODIFY)
Handle hello messages

### 10. Java: ConnectedDevice.java (MODIFY)
Store npub after hello

## Next Steps

Given the complexity, I recommend:

1. **Option A**: Implement full secp256k1 (2-3 hours work, requires careful crypto implementation)
2. **Option B**: Start with simpler HMAC-based auth, upgrade to secp256k1 later
3. **Option C**: Use existing Nostr library (nostr-tools for Dart, nostr-java for Java)

Which approach would you prefer? I want to ensure we implement this correctly and securely.
