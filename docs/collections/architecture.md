# Collections Architecture

## System Overview

The Collections system is built on a layered architecture with clear separation between data models, storage management, business logic, and presentation layers.

## Architecture Layers

```
┌─────────────────────────────────────────┐
│         UI Layer (Fragments)            │
│  CollectionsFragment, BrowserFragment   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Business Logic (Managers)          │
│  CollectionLoader, KeysManager, Prefs   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│       Data Models (POJOs)               │
│  Collection, CollectionFile, Security   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Storage Layer (File System)        │
│    App Files Dir, SharedPreferences     │
└─────────────────────────────────────────┘
```

## Core Components

### 1. Data Models

#### Collection.java
The central data model representing a complete collection.

**Location**: `app/src/main/java/offgrid/geogram/models/Collection.java`

**Key Fields**:
- `id` (String): Nostr npub identifier
- `title` (String): Display title
- `description` (String): Collection description
- `thumbnailPath` (String): Path to thumbnail image
- `totalSize` (long): Total bytes of all files
- `filesCount` (int): Number of files
- `updated` (long): Last update timestamp
- `storagePath` (String): Filesystem path
- `isOwned` (boolean): User owns this collection
- `isFavorite` (boolean): User favorited this collection
- `security` (CollectionSecurity): Security configuration
- `files` (List<CollectionFile>): File tree

**Methods**:
- `getFormattedSize()`: Human-readable size string

#### CollectionFile.java
Represents individual files and directories within a collection.

**Location**: `app/src/main/java/offgrid/geogram/models/CollectionFile.java`

**Key Fields**:
- `path` (String): Full path relative to collection root
- `name` (String): Display name
- `type` (FileType): DIRECTORY or FILE
- `size` (long): File size in bytes
- `mimeType` (String): MIME type
- `description` (String): Optional description
- `views` (int): View count

**Methods**:
- `isDirectory()`: Check if directory
- `getFormattedSize()`: Human-readable size
- `getFileExtension()`: Extract extension

#### CollectionSecurity.java
Security and permission configuration.

**Location**: `app/src/main/java/offgrid/geogram/models/CollectionSecurity.java`

**Key Fields**:
- `version` (String): Schema version
- `visibility` (Visibility): PUBLIC, PRIVATE, PASSWORD, GROUP
- `publicRead` (boolean): Allow public read
- `allowSubmissions` (boolean): Allow file submissions
- `submissionRequiresApproval` (boolean): Approval workflow
- `canUsersComment/Like/Dislike/Rate` (boolean): User permissions
- `whitelistedUsers` (List<String>): Allowed npubs
- `blockedUsers` (List<String>): Blocked npubs
- `contentWarnings` (List<String>): Content warning tags
- `ageRestrictionEnabled` (boolean): Age gate
- `minimumAge` (int): Minimum age
- `encryptionEnabled` (boolean): Encryption toggle

**Methods**:
- `fromJSON(JSONObject)`: Parse from security.json
- `toJSON()`: Serialize to JSON
- `isPubliclyAccessible()`: Check access level

### 2. Business Logic Managers

#### CollectionLoader.java
Main parser and loader for collections from storage.

**Location**: `app/src/main/java/offgrid/geogram/util/CollectionLoader.java`

**Responsibilities**:
- Load all collections from app storage
- Parse collection.js, security.json, tree-data.js
- Scan folders for files
- Generate/update tree-data.js with SHA1 hashes
- Calculate total sizes and file counts

**Key Methods**:
- `loadCollectionsFromAppStorage(Context)`: Load all collections
- `loadCollectionFromFolder(Context, File)`: Load single collection
- `loadFilesFromTreeDataJs(Collection, File)`: Parse tree-data.js
- `scanFolder(Collection, File, String)`: Recursively scan folder
- `generateTreeDataJs(Collection, File)`: Generate file index

**File Parsing**:
- Extracts JSON from JavaScript files using substring extraction
- Pattern: `window.COLLECTION_DATA = {json}` → extract `{json}`
- Handles missing files with sensible defaults

#### CollectionKeysManager.java
Manages collection Nostr key pairs (npub/nsec).

**Location**: `app/src/main/java/offgrid/geogram/util/CollectionKeysManager.java`

**Responsibilities**:
- Store collection private keys (nsec)
- Retrieve keys by collection ID (npub)
- Determine ownership status
- Persist keys to JSON file

**Key Methods**:
- `storeKeys(Context, npub, nsec)`: Save key pair
- `getNsec(Context, npub)`: Get private key
- `isOwnedCollection(Context, npub)`: Check ownership
- `getAllOwnedCollections(Context)`: List all owned

**Storage**:
- File: `{filesDir}/collection_keys_config.json`
- Format: `{ "npub...": { "npub": "...", "nsec": "...", "created": ... } }`

#### CollectionPreferences.java
Manages user preferences for collections.

**Location**: `app/src/main/java/offgrid/geogram/util/CollectionPreferences.java`

**Responsibilities**:
- Track favorited collections
- Store user-specific settings
- Persist preferences

**Key Methods**:
- `setFavorite(Context, collectionId, boolean)`: Toggle favorite
- `isFavorite(Context, collectionId)`: Check favorite status
- `getAllFavorites(Context)`: Get all favorites

**Storage**:
- SharedPreferences: `collection_preferences`
- Key pattern: `favorite_{collectionId}` → boolean

### 3. UI Layer

#### CollectionsFragment.java
Main collections list screen.

**Location**: `app/src/main/java/offgrid/geogram/fragments/CollectionsFragment.java`

**Features**:
- Grid RecyclerView of collections
- Search/filter functionality
- Swipe-to-refresh
- Create collection FAB
- Long-press context menu (favorite/delete)
- Broadcast receiver for collection changes

**Lifecycle**:
1. Load collections on background thread
2. Display in RecyclerView via CollectionAdapter
3. Listen for user interactions
4. Update preferences/storage as needed

#### CollectionBrowserFragment.java
File browser within a collection.

**Location**: `app/src/main/java/offgrid/geogram/fragments/CollectionBrowserFragment.java`

**Features**:
- Hierarchical folder navigation
- File search across entire collection
- File operations (rename, delete, add)
- Remote mode for P2P access
- Torrent generation
- File opening with system apps

**Navigation**:
- Maintains current path state
- Breadcrumb navigation
- Back button handling
- Deep linking support

**Remote Mode**:
- Fetches file list from P2PHttpClient
- Downloads files on-demand
- Caches remote files locally

#### CreateCollectionFragment.java
Collection creation wizard.

**Location**: `app/src/main/java/offgrid/geogram/fragments/CreateCollectionFragment.java`

**Workflow**:
1. User enters title and description
2. Select auto-folder or custom folder
3. Generate Nostr key pair (npub/nsec)
4. Scan folder for files
5. Create metadata files:
   - collection.js
   - extra/security.json
   - extra/tree-data.js
6. Store keys in CollectionKeysManager
7. Navigate to new collection

#### CollectionSettingsFragment.java
Security and permission configuration.

**Location**: `app/src/main/java/offgrid/geogram/fragments/CollectionSettingsFragment.java`

**Features**:
- Visibility level selection
- Group member management
- Permission toggles
- Save to security.json

#### CollectionInfoFragment.java
Collection information and sharing.

**Location**: `app/src/main/java/offgrid/geogram/fragments/CollectionInfoFragment.java`

**Features**:
- Display collection ID (npub)
- Copy to clipboard
- Open file browser
- Access torrent files

#### RemoteCollectionsFragment.java
Browse collections from remote P2P devices.

**Location**: `app/src/main/java/offgrid/geogram/fragments/RemoteCollectionsFragment.java`

**Features**:
- Fetch collections via P2PHttpClient API
- Display remote collections
- Navigate to remote browser

### 4. Adapters

#### CollectionAdapter.java
RecyclerView adapter for collection list.

**Location**: `app/src/main/java/offgrid/geogram/adapters/CollectionAdapter.java`

**Responsibilities**:
- Bind Collection objects to list item views
- Handle click and long-click events
- Display thumbnails, metadata, stats
- Show admin badge and favorite star

## Storage Architecture

### File System Layout

```
{appFilesDir}/
├── collections/                    # Collections root
│   ├── npub1abc.../               # Collection folder (named by npub)
│   │   ├── collection.js          # Collection metadata
│   │   ├── extra/                 # Extra metadata folder
│   │   │   ├── security.json      # Security configuration
│   │   │   ├── tree-data.js       # File index with SHA1 hashes
│   │   │   └── collection_*.torrent  # Torrent files
│   │   ├── folder1/               # User folders
│   │   │   ├── file1.txt
│   │   │   └── file2.pdf
│   │   └── image.jpg
│   └── npub2def.../
│       └── ...
└── collection_keys_config.json     # Private key storage
```

### SharedPreferences

```
collection_preferences
├── favorite_npub1abc... = true
├── favorite_npub2def... = false
└── ...
```

## Integration Points

### Nostr Protocol
- Uses NostrKeyGenerator for npub/nsec generation
- Collections identified by npub
- Future: Nostr events for collection updates

### P2P Networking
- P2PHttpClient for remote collection access
- API endpoints:
  - GET `/collections` - List collections
  - GET `/collections/{npub}` - Get collection metadata
  - GET `/collections/{npub}/files` - Get file tree
  - GET `/collections/{npub}/files/{path}` - Download file

### Torrent System
- TorrentGenerator creates .torrent files
- Stored in `extra/` folder
- Enables BitTorrent distribution

### Device Management
- RemoteProfileCache for device info
- DeviceManager for connection tracking
- Bluetooth and WiFi Direct support

## Data Flow

### Loading Collections

```
User opens app
    ↓
CollectionsFragment.loadCollections()
    ↓
CollectionLoader.loadCollectionsFromAppStorage(context)
    ↓
For each folder in collections/:
    ↓
    CollectionLoader.loadCollectionFromFolder(context, folder)
        ↓
        Parse collection.js → Collection object
        ↓
        Parse extra/security.json → CollectionSecurity
        ↓
        Parse extra/tree-data.js → List<CollectionFile>
        ↓
        Check CollectionKeysManager.isOwnedCollection() → isOwned
        ↓
        Check CollectionPreferences.isFavorite() → isFavorite
        ↓
    Return Collection
    ↓
Display in RecyclerView via CollectionAdapter
```

### Creating Collection

```
User taps FAB
    ↓
CreateCollectionFragment shows form
    ↓
User enters title, description, folder
    ↓
User taps Save
    ↓
NostrKeyGenerator.generateKeyPair() → (npub, nsec)
    ↓
Create folder: collections/{npub}/
    ↓
Scan selected folder for files
    ↓
Generate collection.js with metadata
    ↓
Generate extra/security.json with defaults
    ↓
Generate extra/tree-data.js with file hashes
    ↓
CollectionKeysManager.storeKeys(npub, nsec)
    ↓
Navigate to CollectionBrowserFragment
```

### Remote Collection Access

```
User opens RemoteCollectionsFragment
    ↓
P2PHttpClient.fetchCollections(deviceIp) → List<Collection>
    ↓
Display in RecyclerView
    ↓
User taps collection
    ↓
Navigate to CollectionBrowserFragment (remote mode)
    ↓
P2PHttpClient.fetchCollectionFiles(deviceIp, npub) → List<CollectionFile>
    ↓
Display files
    ↓
User taps file
    ↓
P2PHttpClient.downloadFile(deviceIp, npub, filePath) → File
    ↓
Open file with system app
```

## Security Considerations

### Key Storage
- Private keys (nsec) stored in app-private files
- Not exported or backed up by default
- Lost keys = lost collection ownership

### File Access
- Collections stored in app-private directory
- Not accessible to other apps without permission
- Remote access requires P2P connection

### Signature Verification
- collection.js includes signature field (future)
- Verify authenticity using npub
- Prevent tampering

## Performance Optimizations

### Lazy Loading
- Collections loaded on background thread
- File scanning deferred until needed
- Thumbnails loaded asynchronously

### Caching
- Collection list cached in memory
- File tree cached until invalidated
- Remote profile cache for device info

### Incremental Updates
- Only regenerate tree-data.js when files change
- SHA1 hashes cached in tree-data.js
- Avoid full folder scans on startup

## Future Enhancements

### Planned Features
- Encryption support (AES-256)
- Password-protected collections
- Nostr event publishing for updates
- Distributed hash table (DHT) for discovery
- Differential updates for sync
- Collection versioning

### Scalability
- Support for large collections (10,000+ files)
- Streaming file downloads
- Partial file synchronization
- Multi-device sync

## Related Documentation

- [File Formats](file-formats.md) - Detailed file specifications
- [Security Model](security-model.md) - Security architecture
- [API Reference](api-reference.md) - Programming interfaces
- [P2P Integration](p2p-integration.md) - Remote access details
