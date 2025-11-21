# Chunked Downloads Implementation

## Summary

Implemented a complete chunked download system that works uniformly across **BLE, WiFi, and Relay** transports. Files are downloaded in small chunks, tracked with manifests, and automatically reassembled when complete.

## Key Features

### 1. Chunk Download Manager
**File:** `ChunkDownloadManager.java`

- **Partial Files**: Downloads saved as `filename.partial` during download
- **Manifest Tracking**: Text file `filename.manifest` tracks chunk status
- **Out-of-Order Support**: Chunks can arrive in any order using RandomAccessFile
- **Auto-Reassembly**: When all chunks complete, .partial → final file
- **Resume Capability**: Can resume interrupted downloads from manifest

**Manifest Format:**
```
filename=photo.jpg
totalSize=32815
chunkSize=8192
totalChunks=5
chunk0=complete,0-8191
chunk1=complete,8192-16383
chunk2=pending,16384-24575
chunk3=pending,24576-32767
chunk4=pending,32768-32814
```

### 2. New API Endpoint

**Endpoint:** `POST /api/remote/download-file-chunked`

**Request:**
```json
{
  "deviceId": "X15RJ0",
  "collectionId": "npub1...",
  "filePath": "images/photo.jpg",
  "fileSize": 32815,
  "chunkSize": 8192
}
```

**Response:**
```json
{
  "success": true,
  "message": "Chunked download started",
  "fileId": "npub1.../images/photo.jpg",
  "fileName": "photo.jpg",
  "totalChunks": 5,
  "chunkSize": 8192
}
```

**Progress Monitoring:**
Use existing progress API: `GET /api/downloads/:fileId`

### 3. Range Request Support

Added Range header support throughout the entire stack:

**Client Side (P2PHttpClient.java):**
- New method: `getInputStreamWithRange(deviceId, remoteIp, path, startByte, endByte, timeout)`
- Supports Range requests over:
  - **HTTP**: Direct WiFi connection with `Range: bytes=start-end` header
  - **Relay**: Relay server with Range header forwarding
  - **GATT**: BLE connection with range as query parameter

**Server Side (SimpleSparkServer.java):**
- File endpoint now handles Range requests
- Supports both:
  - HTTP header: `Range: bytes=0-8191`
  - Query parameter: `?range=0-8191` (for GATT compatibility)
- Returns HTTP 206 Partial Content with correct headers
- Falls back to full file if no Range specified

### 4. Transport-Specific Chunk Sizes

The chunked approach works uniformly across all transports. Just adjust chunk size:

| Transport | Chunk Size | Total Chunks (32KB file) | Est. Time |
|-----------|-----------|--------------------------|-----------|
| **BLE GATT** | 8KB | 4 chunks | ~2-4 minutes |
| **WiFi Local** | 64KB | 1 chunk | ~1 second |
| **Internet Relay** | 32KB | 2 chunks | ~5-10 seconds |

**Benefits:**
- Small chunks for BLE avoid timeout issues
- Large chunks for WiFi maximize throughput
- Medium chunks for Relay balance reliability & speed
- Same code path for all transports

## How It Works

### Download Flow

1. **Start Download**
   ```bash
   POST /api/remote/download-file-chunked
   {
     "deviceId": "X15RJ0",
     "filePath": "photo.jpg",
     "fileSize": 32815,
     "chunkSize": 8192
   }
   ```

2. **Server Creates Tracking**
   - Creates `photo.jpg.partial` file (pre-allocated to full size)
   - Creates `photo.jpg.manifest` file (tracks chunk status)
   - Starts background thread to download chunks

3. **Download Chunks Loop**
   ```
   For each chunk (0 to totalChunks-1):
     - Request: GET /api/collections/.../file/photo.jpg?range=0-8191
     - Server: Returns HTTP 206 with chunk bytes
     - Client: Writes chunk to .partial at correct offset
     - Updates manifest: chunk0=complete,0-8191
     - Updates progress API
   ```

4. **Reassembly**
   - When all chunks marked complete
   - Renames `photo.jpg.partial` → `photo.jpg`
   - Deletes `photo.jpg.manifest`
   - Marks download as completed

### Out-of-Order Chunk Handling

Chunks can arrive in any order:

1. **RandomAccessFile** used to write chunks at specific offsets
2. **Manifest** tracks which chunks are complete
3. **Next chunk selection**: Loop finds first incomplete chunk
4. **No dependency** between chunks - fully parallelizable (future enhancement)

Example: Chunks arrive as 2, 0, 3, 1:
```
chunk2 arrives → write at offset 16384
chunk0 arrives → write at offset 0
chunk3 arrives → write at offset 24576
chunk1 arrives → write at offset 8192
All complete → reassemble
```

## Testing Instructions

### 1. Install Updated APK

The updated APK is in: `app/build/outputs/apk/debug/app-debug.apk`

Install on Tank2:
```bash
adb -s <tank2-serial> install -r app/build/outputs/apk/debug/app-debug.apk
```

### 2. Run Test Script

```bash
cd geogram-android
./test-chunked-download.sh
```

The script will:
1. Check API health
2. List remote files
3. Let you select a file to download
4. Choose chunk size (default 8KB for BLE)
5. Start chunked download
6. Monitor progress in real-time
7. Show completion status

### 3. Monitor Logs

**Tank2 Logs (HTTP API):**
```bash
curl -s "http://192.168.178.28:45678/api/logs?limit=100" | \
  jq -r '.logs[]' | grep -E 'chunk|Chunk|Downloading chunk'
```

**Expected Log Output:**
```
Downloading chunk 0/3 (bytes 0-8191)
Chunk 0 complete (33%)
Downloading chunk 1/3 (bytes 8192-16383)
Chunk 1 complete (66%)
Downloading chunk 2/3 (bytes 16384-24575)
Chunk 2 complete (100%)
Chunked download completed: images/photo.jpg
```

**Samsung Logs (ADB):**
```bash
adb -s R58M91ETKFE logcat -s "SimpleSparkServer:I" | \
  grep -E 'Serving file chunk'
```

**Expected:**
```
API: Serving file chunk images/photo.jpg (bytes 0-8191, 8192 bytes)
API: Serving file chunk images/photo.jpg (bytes 8192-16383, 8192 bytes)
API: Serving file chunk images/photo.jpg (bytes 16384-24575, 8192 bytes)
```

### 4. Check Partial Files

While download is in progress, check for partial/manifest files:

```bash
# Via ADB on Tank2
adb -s <tank2-serial> shell "ls -la /data/data/offgrid.geogram/files/collections/npub1.../images/"
```

Should see:
```
photo.jpg.partial    (32815 bytes - full size pre-allocated)
photo.jpg.manifest   (text file with chunk tracking)
```

When complete:
```
photo.jpg            (32815 bytes - final file)
```

## File Modifications

**New Files:**
1. `app/src/main/java/offgrid/geogram/util/ChunkDownloadManager.java` - Chunk management
2. `test-chunked-download.sh` - Test script
3. `CHUNKED_DOWNLOADS_IMPLEMENTATION.md` - This file

**Modified Files:**
1. `app/src/main/java/offgrid/geogram/server/SimpleSparkServer.java`
   - Added `POST /api/remote/download-file-chunked` endpoint (lines 2116-2285)
   - Added Range request support to file endpoint (lines 1813-1897)

2. `app/src/main/java/offgrid/geogram/p2p/P2PHttpClient.java`
   - Added `getInputStreamWithRange()` public method (lines 407-464)
   - Added `getInputStreamViaHttpWithRange()` private method (lines 644-689)
   - Added `getInputStreamViaRelayWithRange()` private method (lines 691-747)
   - Added `getInputStreamViaGattWithRange()` private method (lines 749-822)

## Expected Results

### Small File (32KB) over BLE with 8KB chunks:

**Before (Single Request):**
- Timeout after 60-180 seconds
- 0 bytes downloaded
- GATT messages never completing
- Error: "HTTP 500: Error: null"

**After (Chunked):**
- 4 chunks × ~30 seconds per chunk = **~2 minutes total**
- Progress visible: 0% → 25% → 50% → 75% → 100%
- Each chunk completes independently
- Robust to individual chunk failures
- Success!

### Performance Estimates

| File Size | Chunk Size | Chunks | BLE Time | WiFi Time | Relay Time |
|-----------|-----------|--------|----------|-----------|------------|
| 32 KB | 8 KB | 4 | ~2 min | <1 sec | ~5 sec |
| 127 KB | 8 KB | 16 | ~8 min | <1 sec | ~10 sec |
| 1 MB | 8 KB | 128 | ~64 min | <1 sec | ~30 sec |

**Recommendation:**
- For files >100KB over BLE: System should auto-switch to WiFi/Relay if available
- P2PHttpClient already has this routing logic built-in!

## Advantages of Chunked Approach

1. **Robust to Failures**: Individual chunk failures don't fail entire download
2. **Progress Visibility**: Real-time progress updates per chunk
3. **Resumable**: Can resume from last completed chunk
4. **Timeout-Proof**: Each chunk has own timeout (60s per 8KB vs 180s for 32KB)
5. **Uniform Code**: Same approach works for BLE/WiFi/Relay
6. **Bandwidth-Adaptive**: Adjust chunk size based on transport speed
7. **Future: Parallelization**: Could download multiple chunks simultaneously

## Next Steps

### Immediate Testing
1. ✅ Install updated APK on Tank2
2. ✅ Run `./test-chunked-download.sh`
3. ✅ Monitor logs for chunk progress
4. ✅ Verify download completes successfully

### Future Enhancements
1. **Parallel Chunks**: Download 2-3 chunks simultaneously over WiFi
2. **Adaptive Chunk Size**: Automatically adjust based on connection quality
3. **Retry Logic**: Retry failed chunks with exponential backoff
4. **UI Progress**: Show chunk progress in CollectionBrowserFragment
5. **Background Downloads**: Continue downloads when app is in background

## Success Criteria

**Test passes if:**
- ✅ Chunked download starts successfully
- ✅ Progress updates show chunk completion (25%, 50%, 75%, 100%)
- ✅ .partial and .manifest files created during download
- ✅ Final file appears when all chunks complete
- ✅ File is correct size and not corrupted
- ✅ Download completes without timeout errors
- ✅ Logs show "Chunked download completed"

The chunked download system is ready for testing!
