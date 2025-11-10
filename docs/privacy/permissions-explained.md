# Geogram Android App - Permissions Explained

**Version**: 1.0
**Last Updated**: 2025-11-10
**Status**: Complete

---

## Overview

Geogram is designed for **offline-first, privacy-focused communication**. We believe in transparency about what permissions we request and exactly how they are used. This document provides an extensive explanation of each Android permission, the specific code that uses it, and verification links to the source code.

---

## Table of Contents

1. [Bluetooth Permissions](#bluetooth-permissions)
2. [Location Permissions](#location-permissions)
3. [Battery Optimization](#battery-optimization)
4. [Internet Permission](#internet-permission)
5. [Foreground Service Permissions](#foreground-service-permissions)
6. [Boot and Wake Lock Permissions](#boot-and-wake-lock-permissions)
7. [Permission Request Flow](#permission-request-flow)
8. [Privacy Guarantees](#privacy-guarantees)

---

## Bluetooth Permissions

### Permissions Requested

- `android.permission.BLUETOOTH` (Android <12)
- `android.permission.BLUETOOTH_ADMIN` (Android <12)
- `android.permission.BLUETOOTH_SCAN` (Android ≥12)
- `android.permission.BLUETOOTH_ADVERTISE` (Android ≥12)
- `android.permission.BLUETOOTH_CONNECT` (Android ≥12)

### Why We Need It

Bluetooth Low Energy (BLE) is the **core technology** that enables Geogram's offline mesh networking. Without Bluetooth, the app cannot discover nearby devices or exchange messages in offline environments.

### How It's Used

1. **BLE Device Discovery**
   - Scanning for nearby Geogram devices (phones, ESP32 beacons)
   - Broadcasting presence to allow other devices to discover you
   - **Code**: [BluetoothReceiver.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/ble/BluetoothReceiver.java)

2. **Message Exchange**
   - Direct device-to-device message transfer via BLE
   - Relay message synchronization between nearby devices
   - **Code**: [BluetoothSender.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/ble/BluetoothSender.java)

3. **Connection Management**
   - Establishing secure BLE connections
   - Managing multiple simultaneous connections
   - **Code**: [EventBleMessageReceived.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/ble/events/EventBleMessageReceived.java)

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:10-14](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L10-L14)

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

**Permission Check**:
[PermissionsHelper.java:28-35](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/PermissionsHelper.java#L28-L35)

```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
    permissions.add(Manifest.permission.BLUETOOTH_SCAN);
    permissions.add(Manifest.permission.BLUETOOTH_ADVERTISE);
    permissions.add(Manifest.permission.BLUETOOTH_CONNECT);
} else {
    permissions.add(Manifest.permission.BLUETOOTH);
    permissions.add(Manifest.permission.BLUETOOTH_ADMIN);
}
```

---

## Location Permissions

### Permissions Requested

- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`

### Why We Need It

**Android System Requirement**: Starting with Android 6.0 (API 23), the Android operating system **requires** location permission for any app that performs Bluetooth scanning. This is a privacy safeguard imposed by Google, not a choice by Geogram developers.

### How It's Used

1. **BLE Scanning Requirement (Mandatory)**
   - Android will not allow BLE scanning without location permission
   - This is an Android OS restriction, not a Geogram feature requirement
   - **Even if we wanted to, we cannot scan for Bluetooth devices without this permission**

2. **Geographic Message Tagging (Optional)**
   - When enabled, messages can include GPS coordinates
   - Used for relay routing (messages can target geographic areas)
   - Users can disable location tagging in Settings
   - **Code**: [UpdatedCoordinates.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/apps/loops/UpdatedCoordinates.java)

3. **Relay Stamping (Optional)**
   - Relay nodes can stamp messages with their location
   - Helps track message propagation paths
   - Users can disable relay mode entirely
   - **Code**: See [relay-protocol.md](../relay/relay-protocol.md)

### What We DO NOT Do

- ❌ We do **NOT** track your location continuously
- ❌ We do **NOT** send location data to any server (unless you explicitly share it in a message)
- ❌ We do **NOT** build location profiles
- ❌ We do **NOT** sell or share location data with third parties

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:16-17](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L16-L17)

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

**Permission Check**:
[PermissionsHelper.java:37-40](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/PermissionsHelper.java#L37-L40)

```java
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
    permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION);
}
```

---

## Battery Optimization

### Permission Requested

- `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

### Why We Need It

When you enable **Relay Mode**, your device acts as a message carrier, forwarding messages to other devices even when the app is in the background. Android's battery optimization would kill the background service, breaking the relay network.

### How It's Used

1. **Background Service Operation**
   - Keeps the app alive when relay mode is enabled
   - Allows continuous BLE scanning and message synchronization
   - **Code**: [BackgroundService.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/BackgroundService.java)

2. **User Control**
   - Battery optimization exemption is requested only if you enable relay mode
   - You can disable relay mode at any time in Settings
   - **Code**: [BatteryOptimizationHelper.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/util/BatteryOptimizationHelper.java)

### Battery Impact

- Relay mode **will increase battery usage** due to continuous Bluetooth scanning
- You can monitor battery usage in Android Settings → Battery
- You can disable relay mode when battery is low

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:32](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L32)

```xml
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

**Permission Check**:
[PermissionsHelper.java:46](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/PermissionsHelper.java#L46)

```java
permissions.add(Manifest.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
```

---

## Internet Permission

### Permission Requested

- `android.permission.INTERNET`

### Why We Need It

Geogram supports **hybrid communication**: it works fully offline via Bluetooth, but can also use internet when available for faster message delivery via NOSTR relays.

### How It's Used

1. **NOSTR Protocol Communication**
   - Connects to decentralized NOSTR relays over the internet
   - Sends and receives encrypted messages via NOSTR
   - **Code**: See [geogram-server](https://github.com/geograms/geogram-server) for NOSTR integration

2. **Optional HTTP API**
   - Fetching user profiles from NOSTR relays
   - Synchronizing messages when internet is available

### What We DO NOT Do

- ❌ We do **NOT** send telemetry or analytics
- ❌ We do **NOT** connect to advertising networks
- ❌ We do **NOT** require internet to function (app works fully offline)
- ❌ We do **NOT** track your browsing or collect personal data

### Privacy Guarantee

All internet communication uses **end-to-end encryption** via NOSTR's cryptographic protocol (Schnorr signatures). Even NOSTR relay operators cannot read your messages.

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:21](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L21)

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

---

## Foreground Service Permissions

### Permissions Requested

- `android.permission.FOREGROUND_SERVICE`
- `android.permission.FOREGROUND_SERVICE_DATA_SYNC`
- `android.permission.FOREGROUND_SERVICE_LOCATION`

### Why We Need It

Foreground services allow the app to run in the background with a persistent notification, ensuring relay functionality is not killed by Android.

### How It's Used

1. **Relay Mode Background Service**
   - Runs as a foreground service when relay mode is enabled
   - Shows a notification to inform you the app is running
   - **Code**: [BackgroundService.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/BackgroundService.java)

2. **Data Synchronization**
   - Syncs messages with nearby devices in the background
   - Forwards relay messages to other nodes

3. **Location Service Type**
   - Required for foreground services that use location (for relay stamping)

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:22-24](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L22-L24)

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

**Service Configuration**:
[AndroidManifest.xml:76-79](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L76-L79)

```xml
<service
    android:name="offgrid.geogram.core.BackgroundService"
    android:exported="false"
    android:foregroundServiceType="location|dataSync" />
```

---

## Boot and Wake Lock Permissions

### Permissions Requested

- `android.permission.RECEIVE_BOOT_COMPLETED`
- `android.permission.WAKE_LOCK`

### Why We Need It

If relay mode is enabled, the service should restart automatically when the device boots, so you continue participating in the relay network without manual intervention.

### How It's Used

1. **Auto-Start on Boot**
   - Relay service restarts after device reboot
   - Only if relay mode was previously enabled
   - **Code**: [BootService.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/BootService.java)

2. **Wake Lock**
   - Prevents device from sleeping during critical operations
   - Used sparingly to avoid battery drain

### Verification

**Manifest Declaration**:
[AndroidManifest.xml:27-28](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L27-L28)

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

**Boot Receiver**:
[AndroidManifest.xml:81-87](https://github.com/geograms/geogram-android/blob/main/app/src/main/AndroidManifest.xml#L81-L87)

```xml
<receiver
    android:name="offgrid.geogram.core.BootService"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

---

## Permission Request Flow

### 1. First-Run Intro Screen

When you launch Geogram for the first time, you see a permissions explanation screen before any permissions are requested.

**Code**: [PermissionsIntroActivity.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/PermissionsIntroActivity.java)

### 2. Android System Permission Dialogs

After accepting on the intro screen, Android shows its standard permission dialogs for each permission group.

**Code**: [MainActivity.java:90-94](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/MainActivity.java#L90-L94)

```java
if (PermissionsHelper.hasAllPermissions(this)) {
    initializeApp();
} else {
    PermissionsHelper.requestPermissionsIfNecessary(this);
}
```

### 3. Permission Handling

**Code**: [PermissionsHelper.java](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/core/PermissionsHelper.java)

All permission checks and requests are centralized in this helper class, making the code easy to audit.

---

## Privacy Guarantees

### What Data Stays Local

- ✅ All messages stored in local SQLite database ([Room DB](https://github.com/geograms/geogram-android/blob/main/app/src/main/java/offgrid/geogram/database/))
- ✅ NOSTR keys stored locally only (never transmitted unencrypted)
- ✅ User profiles stored as ZIP archives on device
- ✅ Relay messages stored temporarily, auto-expire

### What We Never Do

- ❌ No telemetry or crash reporting
- ❌ No analytics or tracking SDKs
- ❌ No advertising networks
- ❌ No cloud backups without your explicit action
- ❌ No sale or sharing of data with third parties

### Open Source Transparency

The entire Geogram codebase is open source and available for inspection:

- **Android App**: [github.com/geograms/geogram-android](https://github.com/geograms/geogram-android)
- **Central Docs**: [github.com/geograms/central](https://github.com/geograms/central)
- **Server**: [github.com/geograms/geogram-server](https://github.com/geograms/geogram-server)

### Cryptographic Security

- **NOSTR Protocol**: Schnorr signatures (secp256k1) for message authenticity
- **End-to-End Encryption**: Messages encrypted between sender and recipient
- **No Man-in-the-Middle**: Relay nodes cannot read encrypted message content

See [Message Integrity Documentation](../relay/message-integrity.md) for cryptographic details.

---

## Frequently Asked Questions

### Why does a "private" app need location permission?

This is an **Android system requirement**, not a Geogram decision. Google requires all apps that use Bluetooth scanning to request location permission, even if the app never uses GPS. We only use location for optional features (geographic message routing), which can be disabled.

### Can I use Geogram without granting all permissions?

No. Bluetooth and location permissions are **mandatory** for the core functionality (BLE mesh networking). Without them, the app cannot discover nearby devices or exchange messages offline.

### Does Geogram track me?

No. We do not track users, collect analytics, or send telemetry. All data stays on your device unless you explicitly send a message to someone.

### What if I don't trust you?

**Audit the code!** Geogram is fully open source. You can read every line of code, build the app yourself, and verify exactly what it does.

### Can I revoke permissions later?

Yes. You can revoke permissions at any time in Android Settings → Apps → Geogram → Permissions. However, this will disable core functionality (the app cannot work without Bluetooth and location).

---

## Contact & Feedback

If you have questions or concerns about permissions:

- **GitHub Issues**: [Report an issue](https://github.com/geograms/central/issues)
- **GitHub Discussions**: [Start a discussion](https://github.com/geograms/central/discussions)

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors

---

*This document is maintained as part of the Geogram central repository. Last updated: 2025-11-10.*
