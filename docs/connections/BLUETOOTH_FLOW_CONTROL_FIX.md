# Bluetooth GATT Flow Control Implementation

## Problem Summary

**Original Issue:** BLE GATT writes were failing at ~95% rate causing file downloads to timeout.

**Root Cause:** BluetoothSender was sending GATT writes too rapidly without flow control:
- 40+ write attempts per second
- No delays between writes
- No waiting for write confirmations
- No backoff on failures
- Result: Bluetooth stack overwhelmed, 95% failures

**Evidence from Logs:**
```
Samsung (Server):
12:48:01 ✗ GATT write FAILED (40+ per second)
12:48:01 ✓ GATT write queued (only 5 per second)

Tank2 (Client):
HTTP-over-GATT: Added parcel to message NT (1108+ parcels buffered)
Message never completes → HTTP 504 timeout after 60s
```

## Solution Implemented

### Flow Control Mechanisms Added

#### 1. Pending Write Tracking
**Purpose:** Prevent multiple simultaneous writes to same device

**Implementation:**
- `pendingWrites` map tracks if write is in-flight for each device
- Write marked as pending before `writeCharacteristic()` call
- Cleared when `onCharacteristicWrite()` callback fires
- Prevents sending new write until previous one completes

**Code:**
```java
// Before write
pendingWrites.put(deviceAddress, true);
boolean writeResult = gatt.writeCharacteristic(rxChar);

// In callback
pendingWrites.remove(deviceAddress);
```

#### 2. Rate Limiting
**Purpose:** Ensure minimum time between writes to prevent overwhelming BT stack

**Implementation:**
- `lastWriteTimestamp` map tracks when last write occurred
- Enforces `MIN_WRITE_INTERVAL_MS = 100ms` minimum delay
- Schedules retry if attempted too soon
- Reduces from 40+ writes/sec → max 10 writes/sec

**Code:**
```java
long timeSinceLastWrite = now - lastWrite;
if (timeSinceLastWrite < MIN_WRITE_INTERVAL_MS) {
    long waitTime = MIN_WRITE_INTERVAL_MS - timeSinceLastWrite;
    handler.postDelayed(() -> tryToSendNext(), waitTime);
    continue;
}
```

#### 3. Exponential Backoff
**Purpose:** Back off from devices experiencing repeated failures

**Implementation:**
- `writeFailureCount` map tracks consecutive failures per device
- Backoff delay: `BASE_BACKOFF_MS * 2^failures`
- Base delay: 200ms, max delay: 3200ms
- Reset counter on first success

**Backoff Schedule:**
| Failures | Delay |
|----------|-------|
| 1 | 200ms |
| 2 | 400ms |
| 3 | 800ms |
| 4 | 1600ms |
| 5+ | 3200ms |

**Code:**
```java
long backoffDelay = Math.min(
    BASE_BACKOFF_MS * (1L << Math.min(failures, MAX_BACKOFF_FAILURES)),
    MAX_BACKOFF_MS
);
```

#### 4. Write Confirmation Handling
**Purpose:** Only proceed after previous write completes

**Implementation:**
- `onCharacteristicWrite()` callback updated
- On success: Clear pending flag, reset failures, schedule next (after rate limit)
- On failure: Clear pending flag, increment failures, schedule retry (with backoff)

**Code:**
```java
@Override
public void onCharacteristicWrite(BluetoothGatt gatt, ..., int status) {
    if (status == BluetoothGatt.GATT_SUCCESS) {
        pendingWrites.remove(deviceAddress);
        writeFailureCount.remove(deviceAddress);
        handler.postDelayed(() -> tryToSendNext(), MIN_WRITE_INTERVAL_MS);
    } else {
        pendingWrites.remove(deviceAddress);
        int failCount = writeFailureCount.getOrDefault(deviceAddress, 0) + 1;
        writeFailureCount.put(deviceAddress, failCount);
        long backoffDelay = calculateBackoff(failCount);
        handler.postDelayed(() -> tryToSendNext(), backoffDelay);
    }
}
```

## Expected Results

### Before Fix
- **Write Rate:** 40+ attempts/second
- **Success Rate:** ~5% (1-2 writes/sec succeed)
- **Failure Rate:** ~95% (38-40 writes/sec fail)
- **Outcome:** Downloads timeout, message never completes

### After Fix
- **Write Rate:** Max 10 attempts/second (100ms minimum interval)
- **Success Rate:** Expected >90%
- **Failure Rate:** Expected <10%
- **Outcome:** Downloads should complete successfully

### Performance Expectations

For a 127KB file over BLE GATT:
- **Parcel size:** ~48 bytes per GATT write
- **Parcels needed:** ~2,650 parcels (127KB / 48 bytes)
- **With flow control:** 10 writes/sec × 90% success = 9 successful/sec
- **Estimated time:** 2,650 / 9 ≈ **~5 minutes** (vs. infinite timeout before)

**Note:** This is still slow for BLE. For larger files, should use WiFi routing when available.

## Configuration Constants

```java
// Flow control tuning parameters (can be adjusted if needed)
private static final long MIN_WRITE_INTERVAL_MS = 100;  // Min delay between writes
private static final long BASE_BACKOFF_MS = 200;        // Base backoff delay
private static final int MAX_BACKOFF_FAILURES = 5;      // Max failures before cap
private static final long MAX_BACKOFF_MS = 3200;        // Max backoff delay
```

### Tuning Guidelines

**If downloads still timeout:**
- Increase `MIN_WRITE_INTERVAL_MS` to 150-200ms (slower but more reliable)

**If downloads work but are very slow:**
- Decrease `MIN_WRITE_INTERVAL_MS` to 75-80ms (faster but less reliable)
- Only do this if success rate remains >85%

**For very congested BT environment:**
- Increase `BASE_BACKOFF_MS` to 300-500ms
- Increase `MAX_BACKOFF_MS` to 5000-10000ms

## Testing Instructions

### 1. Install Updated APK on Both Phones

The updated APK includes flow control fixes in BluetoothSender.java

### 2. Test with Small File First (Recommended)

```bash
# Find a small file (1-5 KB) in the collection
curl -X POST http://192.168.178.28:45678/api/remote/list-files \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"X15RJ0","collectionId":"npub1..."}' | jq '.files[] | select(.size < 5000)'

# Download a small file
curl -X POST http://192.168.178.28:45678/api/remote/download-file \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId":"X15RJ0",
    "collectionId":"npub1...",
    "filePath":"small-file.txt",
    "fileSize":2048
  }'

# Monitor progress
watch -n 2 'curl -s http://192.168.178.28:45678/api/downloads | jq'
```

### 3. Monitor BLE Logs

**On Tank2 (via HTTP API):**
```bash
curl -s "http://192.168.178.28:45678/api/logs?limit=100" | \
  jq -r '.logs[]' | grep -E "GATT write|Rate limiting|Backing off"
```

**On Samsung (via ADB):**
```bash
adb -s R58M91ETKFE logcat -s "BluetoothSender:I" | \
  grep -E "GATT write|✓|✗"
```

### 4. Check Success/Failure Rates

**Expected in logs:**
```
✓ GATT write queued to 77:B6:4F:92:56:F3    ← Should be majority
⏸ Rate limiting - will retry in 85ms         ← Flow control working
⏸ Backing off (failures: 1, wait: 200ms)    ← Backoff on failures
✗ GATT write FAILED                          ← Should be <10%
```

**Success indicators:**
- More ✓ than ✗ logs
- Seeing rate limiting messages (flow control active)
- Download progress increasing steadily
- Downloads completing (not timing out)

### 5. Test with Original 127KB File

After small file succeeds:
```bash
curl -X POST http://192.168.178.28:45678/api/remote/download-file \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId":"X15RJ0",
    "collectionId":"npub13059301306072a8648ce3d020106082a8648ce3d03010703420004ba798",
    "filePath":"6496858977_21432c3327_b.jpg",
    "fileSize":127091
  }'

# Monitor (will take ~5 minutes)
watch -n 5 'curl -s http://192.168.178.28:45678/api/downloads/npub13059301306072a8648ce3d020106082a8648ce3d03010703420004ba798%2F6496858977_21432c3327_b.jpg | jq "{percent: .download.percentComplete, speed: .download.speed, elapsed: (.download.elapsedTimeMs / 1000)}"'
```

## Files Modified

**Location:** `geogram-android/app/src/main/java/offgrid/geogram/ble/BluetoothSender.java`

**Changes:**
1. Added flow control tracking fields (lines 110-122)
2. Updated `sendViaGatt()` method with flow control checks (lines 337-471)
3. Updated `onCharacteristicWrite()` callback to handle completions (lines 1130-1175)
4. Clear tracking maps in `stop()` method (lines 199-202)

**APK:** `app/build/outputs/apk/debug/app-debug.apk` (20 MB)

## Fallback: WiFi Routing

If BLE downloads still have issues, P2PHttpClient should automatically use WiFi when available:
- Both devices on same network: Direct WiFi connection
- Internet relay available: Route through relay
- BLE only: Use GATT (with flow control)

This routing is already implemented in P2PHttpClient - no changes needed.

## Next Steps

1. ✅ Install updated APK on both phones
2. ✅ Test with small file (1-5 KB) first
3. ✅ Monitor logs for success/failure ratio
4. ✅ Test with larger file (127 KB) if small file succeeds
5. ⚠️ If still timing out: Increase `MIN_WRITE_INTERVAL_MS` to 150-200ms
6. 🚀 For production: Use WiFi routing for files >50KB

## Summary

The Bluetooth flow control implementation adds:
- ✅ Write throttling (max 10/sec vs 40+/sec before)
- ✅ Pending write tracking (one at a time per device)
- ✅ Exponential backoff on failures
- ✅ Write confirmation waiting

Expected improvement: **5% → 90%+ success rate** for GATT writes.

This should fix the download timeout issue for BLE file transfers!
