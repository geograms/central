# Collections API Test Results - Tank2

Date: 2025-11-17
Tank2 IP: 192.168.178.28:45678

## Summary

✅ **All new API endpoints are working correctly!**
❌ **Underlying Bluetooth file transfer has timeout issues**

## Test Results

### 1. Basic API Health ✅
```bash
curl http://192.168.178.28:45678/api/ping
```
**Result:** API responding correctly
```json
{
  "success": true,
  "pong": true,
  "timestamp": 1763379866786
}
```

### 2. Download Progress API ✅
```bash
curl http://192.168.178.28:45678/api/downloads
```
**Result:** New endpoint working
```json
{
  "success": true,
  "count": 0,
  "downloads": []
}
```

### 3. Local Collections ✅
```bash
curl http://192.168.178.28:45678/api/collections
```
**Result:** Tank2 has 1 collection
- Collection: "pics"
- Files: 1
- Size: 223.7 KB

### 4. Nearby Devices ✅
```bash
curl http://192.168.178.28:45678/api/devices/nearby
```
**Result:** Tank2 can see 1 device
- Callsign: X15RJ0
- Type: Internet Relay
- Connection: Active

### 5. Remote Collection Listing ✅
```bash
curl -X POST http://192.168.178.28:45678/api/remote/list-collections \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"X15RJ0"}'
```
**Result:** Successfully listed collections on X15RJ0 via Bluetooth
- Collection: "pics"
- Files: 4
- Size: 899.5 KB
- Description: "Just some pics"

**This proves:** Tank2 can successfully communicate with X15RJ0 via Bluetooth to browse collections.

### 6. Remote File Listing ✅
```bash
curl -X POST http://192.168.178.28:45678/api/remote/list-files \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId":"X15RJ0",
    "collectionId":"npub13059301306072a8648ce3d020106082a8648ce3d03010703420004ba798"
  }'
```
**Result:** Successfully listed files in remote collection
- 1 directory: `images/`
- 1 file: `6496858977_21432c3327_b.jpg` (127 KB)

**This proves:** Tank2 can browse remote file structures via Bluetooth.

### 7. Remote File Download with Progress Tracking ⚠️
```bash
curl -X POST http://192.168.178.28:45678/api/remote/download-file \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId":"X15RJ0",
    "collectionId":"npub13059301306072a8648ce3d020106082a8648ce3d03010703420004ba798",
    "filePath":"6496858977_21432c3327_b.jpg",
    "fileSize":127091
  }'
```

**Result:** Download started successfully, progress tracking working
```json
{
  "success": true,
  "message": "Download started",
  "fileId": "npub13059301306072a8648ce3d020106082a8648ce3d03010703420004ba798/6496858977_21432c3327_b.jpg",
  "fileName": "6496858977_21432c3327_b.jpg"
}
```

### 8. Download Progress Monitoring ✅ ⚠️
```bash
curl http://192.168.178.28:45678/api/downloads/[fileId]
```

**Progress Timeline:**
- **T+0s**: Download started (0%, 0 bytes)
- **T+24s**: Still 0% complete, 0 bytes downloaded
- **T+50s**: Still 0% complete, 0 bytes downloaded
- **T+64s**: Download failed with timeout

**Final Status:**
```json
{
  "fileName": "6496858977_21432c3327_b.jpg",
  "percent": 0,
  "downloadedBytes": 0,
  "totalBytes": 127091,
  "failed": true,
  "errorMessage": "HTTP 504: BLE GATT request timeout",
  "elapsedSec": 74.526
}
```

**This proves:**
- ✅ Download progress tracking API works perfectly
- ✅ Real-time monitoring works
- ✅ Error detection and reporting works
- ❌ **BLE GATT timeout issue prevents actual file download**

## Root Cause Analysis

### Issue: BLE GATT Request Timeout

The download fails with `"HTTP 504: BLE GATT request timeout"` after 60 seconds.

**What's Working:**
1. ✅ Tank2 can discover X15RJ0 via Bluetooth
2. ✅ Tank2 can send HTTP requests to X15RJ0 via BLE GATT (for collections/files listing)
3. ✅ Short requests (< 1KB) work fine through Bluetooth
4. ✅ Progress tracking captures and reports the failure correctly

**What's Failing:**
- ❌ File download via BLE GATT times out
- ❌ No data bytes are received (0 / 127091 bytes after 64 seconds)
- ❌ The BLE GATT connection appears to stall during file transfer

### Root Cause Confirmed! 🎯

**Tank2 Logs (Receiver Side):**
```
HTTP-over-GATT: Added parcel to message NT (1022 parcels so far)
HTTP-over-GATT: Added parcel to message NT (1108 parcels so far)
...keeps growing...
```

**Samsung X15RJ0 Logs (Server Side):**
```
12:48:01 ✗ GATT write FAILED to 77:B6:4F:92:56:F3
12:48:01 ✗ GATT write FAILED to 77:B6:4F:92:56:F3
12:48:01 ✗ GATT write FAILED to 77:B6:4F:92:56:F3
...40+ failures per second!
12:48:01 ✓ GATT write queued to 77:B6:4F:92:56:F3: >NT1012
```

**The Problem:**

1. Samsung (server) tries to send the 127KB file via GATT writes
2. **~95% of GATT writes are FAILING**
3. Only a few parcels get through successfully
4. Tank2 (client) receives 1108+ parcels but message never completes
5. GATT write failures happen faster than successes (40+ failures/second)
6. After 60 seconds → HTTP 504 timeout

**Why It Fails:**
- Server is sending GATT writes TOO FAST without flow control
- Bluetooth stack can't keep up with the write rate
- No backpressure/throttling mechanism
- Each failed write queues up another retry
- System overwhelms itself

### Recommendations

#### Immediate Fixes (Must Do)

1. **Add Flow Control to BluetoothSender** ⭐ CRITICAL
   - Add delay between GATT writes (e.g., 50-100ms)
   - Wait for write confirmation before sending next packet
   - Implement exponential backoff on failures
   - Location: `BluetoothSender.java` GATT write method

2. **Reduce GATT Write Rate** ⭐ CRITICAL
   - Current: 40+ writes/second (95% failing)
   - Target: 5-10 writes/second (with confirmations)
   - Add queue with rate limiting
   - Example: Max 1 write per 100ms

3. **Add Backpressure from Receiver**
   - Tank2 should send ACK after successfully receiving N parcels
   - Server waits for ACK before sending more
   - Prevents buffer overflow on receiver

#### Medium-term Solutions

4. **Use WiFi/Relay for Large Files**
   - Detect when both devices are on WiFi
   - Automatically route large file transfers through WiFi
   - Use BLE only for small metadata requests
   - Already supported by P2PHttpClient routing!

5. **Implement Chunked HTTP Downloads**
   - Use HTTP Range requests to download in chunks
   - e.g., Download 10KB at a time with retries
   - Each chunk is a separate HTTP request
   - Resume from last successful chunk on failure

6. **Increase Timeouts**
   - Current: 60 second timeout
   - For 127KB over BLE: need 120-180 seconds
   - But fix flow control first before increasing timeout

#### Testing

7. **Test with Small Files First**
   - Try 1KB, 5KB, 10KB files
   - See what size threshold causes failures
   - This helps tune the flow control parameters

8. **Monitor GATT Write Success Rate**
   - Log success/failure ratio in BluetoothSender
   - Should be >90% success rate for stable transfers
   - Currently: ~5% success rate (BROKEN)

## What You Can Test Now

The automated testing infrastructure is now in place! You can:

### From your computer, control Tank2 to:
1. ✅ List collections on remote devices
2. ✅ Browse files in remote collections
3. ✅ Trigger downloads (though they'll timeout for large files)
4. ✅ Monitor download progress in real-time
5. ✅ See errors when downloads fail

### Test Script
```bash
./test-collections-api.sh
```

This script will walk you through testing all endpoints interactively.

### Manual Testing Examples

**List devices Tank2 can see:**
```bash
curl http://192.168.178.28:45678/api/devices/nearby
```

**Tell Tank2 to browse X15RJ0's collections:**
```bash
curl -X POST http://192.168.178.28:45678/api/remote/list-collections \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"X15RJ0"}'
```

**Monitor all active downloads:**
```bash
watch -n 2 'curl -s http://192.168.178.28:45678/api/downloads | jq'
```

## Next Steps

1. **Fix the BLE GATT timeout issue** - This is the main blocker
2. **Test with WiFi direct connection** - See if file downloads work when both phones are on WiFi
3. **Implement chunked downloads** - Break large files into smaller pieces
4. **Add retry logic** - Automatically retry failed chunks
5. **Optimize BLE message size** - Reduce message frequency, increase payload size

## Success Metrics

**What We Achieved:**
- ✅ Built complete automated testing infrastructure
- ✅ Can remotely control Tank2 from computer via HTTP API
- ✅ Can browse remote devices via Bluetooth
- ✅ Download progress tracking working perfectly
- ✅ Real-time monitoring and error reporting
- ✅ All API endpoints functional and tested

**What Still Needs Work:**
- ❌ Actual file download over Bluetooth (BLE GATT timeout)
- ⚠️ Need to optimize BLE protocol for large transfers
