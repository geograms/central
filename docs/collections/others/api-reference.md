# Collection API Reference

This document provides a complete reference for the Collections programming API.

## Package Structure

```
offgrid.geogram
├── models/
│   ├── Collection.java
│   ├── CollectionFile.java
│   └── CollectionSecurity.java
├── util/
│   ├── CollectionLoader.java
│   ├── CollectionKeysManager.java
│   └── CollectionPreferences.java
├── fragments/
│   ├── CollectionsFragment.java
│   ├── CollectionBrowserFragment.java
│   ├── CreateCollectionFragment.java
│   ├── CollectionSettingsFragment.java
│   ├── CollectionInfoFragment.java
│   └── RemoteCollectionsFragment.java
└── adapters/
    └── CollectionAdapter.java
```

## Data Models

### Collection

**Package**: `offgrid.geogram.models`

**Description**: Main data model representing a collection.

#### Constructors

```java
public Collection()
```
Creates an empty Collection object.

#### Fields

```java
private String id;              // Collection npub
private String title;           // Display title
private String description;     // Description
private String thumbnailPath;   // Thumbnail image path
private long totalSize;         // Total bytes
private int filesCount;         // File count
private long updated;           // Last update timestamp (millis)
private String storagePath;     // Filesystem path
private boolean isOwned;        // User owns this collection
private boolean isFavorite;     // User favorited
private CollectionSecurity security;  // Security config
private List<CollectionFile> files;   // File tree
```

#### Methods

##### getId()
```java
public String getId()
```
Returns the collection npub identifier.

**Returns**: String - Collection npub

##### setId(String id)
```java
public void setId(String id)
```
Sets the collection npub identifier.

**Parameters**:
- `id`: Collection npub

##### getTitle()
```java
public String getTitle()
```
Returns the collection title.

**Returns**: String - Title

##### setTitle(String title)
```java
public void setTitle(String title)
```
Sets the collection title.

**Parameters**:
- `title`: Collection title

##### getDescription()
```java
public String getDescription()
```
Returns the collection description.

**Returns**: String - Description

##### setDescription(String description)
```java
public void setDescription(String description)
```
Sets the collection description.

**Parameters**:
- `description`: Collection description

##### getThumbnailPath()
```java
public String getThumbnailPath()
```
Returns the path to the thumbnail image.

**Returns**: String - Thumbnail path or null

##### setThumbnailPath(String thumbnailPath)
```java
public void setThumbnailPath(String thumbnailPath)
```
Sets the thumbnail image path.

**Parameters**:
- `thumbnailPath`: Path to thumbnail

##### getTotalSize()
```java
public long getTotalSize()
```
Returns the total size of all files in bytes.

**Returns**: long - Total bytes

##### setTotalSize(long totalSize)
```java
public void setTotalSize(long totalSize)
```
Sets the total size in bytes.

**Parameters**:
- `totalSize`: Total bytes

##### getFormattedSize()
```java
public String getFormattedSize()
```
Returns a human-readable size string.

**Returns**: String - Formatted size (e.g., "1.5 MB", "500 KB")

**Example**:
```java
collection.setTotalSize(1572864);
String size = collection.getFormattedSize();  // "1.5 MB"
```

##### getFilesCount()
```java
public int getFilesCount()
```
Returns the number of files in the collection.

**Returns**: int - File count

##### setFilesCount(int filesCount)
```java
public void setFilesCount(int filesCount)
```
Sets the file count.

**Parameters**:
- `filesCount`: Number of files

##### getUpdated()
```java
public long getUpdated()
```
Returns the last update timestamp.

**Returns**: long - Unix timestamp in milliseconds

##### setUpdated(long updated)
```java
public void setUpdated(long updated)
```
Sets the last update timestamp.

**Parameters**:
- `updated`: Unix timestamp in milliseconds

##### getStoragePath()
```java
public String getStoragePath()
```
Returns the filesystem path to collection folder.

**Returns**: String - Absolute path

##### setStoragePath(String storagePath)
```java
public void setStoragePath(String storagePath)
```
Sets the filesystem path.

**Parameters**:
- `storagePath`: Absolute path to collection folder

##### isOwned()
```java
public boolean isOwned()
```
Returns whether the user owns this collection.

**Returns**: boolean - true if user has nsec

##### setOwned(boolean owned)
```java
public void setOwned(boolean owned)
```
Sets the ownership status.

**Parameters**:
- `owned`: true if owned

##### isFavorite()
```java
public boolean isFavorite()
```
Returns whether the user favorited this collection.

**Returns**: boolean - true if favorited

##### setFavorite(boolean favorite)
```java
public void setFavorite(boolean favorite)
```
Sets the favorite status.

**Parameters**:
- `favorite`: true if favorited

##### getSecurity()
```java
public CollectionSecurity getSecurity()
```
Returns the security configuration.

**Returns**: CollectionSecurity - Security config or null

##### setSecurity(CollectionSecurity security)
```java
public void setSecurity(CollectionSecurity security)
```
Sets the security configuration.

**Parameters**:
- `security`: Security config object

##### getFiles()
```java
public List<CollectionFile> getFiles()
```
Returns the file tree.

**Returns**: List<CollectionFile> - List of files and folders

##### setFiles(List<CollectionFile> files)
```java
public void setFiles(List<CollectionFile> files)
```
Sets the file tree.

**Parameters**:
- `files`: List of CollectionFile objects

---

### CollectionFile

**Package**: `offgrid.geogram.models`

**Description**: Represents a file or directory within a collection.

#### Enums

##### FileType
```java
public enum FileType {
    FILE,
    DIRECTORY
}
```

#### Constructors

```java
public CollectionFile()
```

#### Fields

```java
private String path;        // Full path from collection root
private String name;        // Display name
private FileType type;      // FILE or DIRECTORY
private long size;          // File size in bytes
private String mimeType;    // MIME type
private String description; // Optional description
private int views;          // View count
```

#### Methods

##### getPath()
```java
public String getPath()
```
Returns the full path relative to collection root.

**Returns**: String - Path (e.g., "folder/file.txt")

##### setPath(String path)
```java
public void setPath(String path)
```
Sets the path.

**Parameters**:
- `path`: Full path from collection root

##### getName()
```java
public String getName()
```
Returns the file or folder name.

**Returns**: String - Name

##### setName(String name)
```java
public void setName(String name)
```
Sets the name.

**Parameters**:
- `name`: File or folder name

##### getType()
```java
public FileType getType()
```
Returns the file type.

**Returns**: FileType - FILE or DIRECTORY

##### setType(FileType type)
```java
public void setType(FileType type)
```
Sets the file type.

**Parameters**:
- `type`: FILE or DIRECTORY

##### isDirectory()
```java
public boolean isDirectory()
```
Returns whether this is a directory.

**Returns**: boolean - true if directory

**Example**:
```java
if (file.isDirectory()) {
    // Navigate into folder
}
```

##### getSize()
```java
public long getSize()
```
Returns the file size in bytes.

**Returns**: long - Size in bytes (0 for directories)

##### setSize(long size)
```java
public void setSize(long size)
```
Sets the file size.

**Parameters**:
- `size`: Size in bytes

##### getFormattedSize()
```java
public String getFormattedSize()
```
Returns a human-readable size string.

**Returns**: String - Formatted size

##### getMimeType()
```java
public String getMimeType()
```
Returns the MIME type.

**Returns**: String - MIME type (e.g., "text/plain")

##### setMimeType(String mimeType)
```java
public void setMimeType(String mimeType)
```
Sets the MIME type.

**Parameters**:
- `mimeType`: MIME type string

##### getFileExtension()
```java
public String getFileExtension()
```
Extracts the file extension from the path.

**Returns**: String - Extension (e.g., "txt") or empty string

**Example**:
```java
file.setPath("docs/readme.md");
String ext = file.getFileExtension();  // "md"
```

##### getDescription()
```java
public String getDescription()
```
Returns the optional file description.

**Returns**: String - Description or null

##### setDescription(String description)
```java
public void setDescription(String description)
```
Sets the file description.

**Parameters**:
- `description`: Description text

##### getViews()
```java
public int getViews()
```
Returns the view count.

**Returns**: int - Number of views

##### setViews(int views)
```java
public void setViews(int views)
```
Sets the view count.

**Parameters**:
- `views`: View count

---

### CollectionSecurity

**Package**: `offgrid.geogram.models`

**Description**: Security and permission configuration.

#### Enums

##### Visibility
```java
public enum Visibility {
    PUBLIC,
    PRIVATE,
    PASSWORD,
    GROUP
}
```

#### Constructors

```java
public CollectionSecurity()
```

#### Fields

```java
private String version;                      // Schema version
private Visibility visibility;               // Access level
private boolean publicRead;                  // Public read access
private boolean allowSubmissions;            // Allow file submissions
private boolean submissionRequiresApproval;  // Approval workflow
private boolean canUsersComment;             // Comment permission
private boolean canUsersLike;                // Like permission
private boolean canUsersDislike;             // Dislike permission
private boolean canUsersRate;                // Rating permission
private List<String> whitelistedUsers;       // Allowed npubs
private List<String> blockedUsers;           // Blocked npubs
private List<String> contentWarnings;        // Content warning tags
private boolean ageRestrictionEnabled;       // Age gate
private int minimumAge;                      // Minimum age
private boolean encryptionEnabled;           // Encryption toggle
```

#### Static Methods

##### fromJSON(JSONObject json)
```java
public static CollectionSecurity fromJSON(JSONObject json) throws JSONException
```
Parses a CollectionSecurity from JSON.

**Parameters**:
- `json`: JSONObject from security.json

**Returns**: CollectionSecurity - Parsed security config

**Throws**: JSONException - If JSON is malformed

**Example**:
```java
String jsonString = readFile("extra/security.json");
JSONObject json = new JSONObject(jsonString);
CollectionSecurity security = CollectionSecurity.fromJSON(json);
```

#### Instance Methods

##### toJSON()
```java
public JSONObject toJSON() throws JSONException
```
Serializes the security config to JSON.

**Returns**: JSONObject - JSON representation

**Throws**: JSONException - If serialization fails

**Example**:
```java
CollectionSecurity security = new CollectionSecurity();
security.setVisibility(Visibility.PUBLIC);
JSONObject json = security.toJSON();
saveFile("extra/security.json", json.toString());
```

##### isPubliclyAccessible()
```java
public boolean isPubliclyAccessible()
```
Checks if collection is publicly accessible.

**Returns**: boolean - true if public read is enabled

**Example**:
```java
if (security.isPubliclyAccessible()) {
    // Allow anonymous access
}
```

##### Getters and Setters
Standard getters/setters for all fields (see Fields section).

---

## Utility Classes

### CollectionLoader

**Package**: `offgrid.geogram.util`

**Description**: Loads and parses collections from filesystem.

#### Static Methods

##### loadCollectionsFromAppStorage(Context context)
```java
public static List<Collection> loadCollectionsFromAppStorage(Context context)
```
Loads all collections from app storage.

**Parameters**:
- `context`: Android Context

**Returns**: List<Collection> - All collections found

**Example**:
```java
List<Collection> collections = CollectionLoader.loadCollectionsFromAppStorage(context);
for (Collection collection : collections) {
    Log.d(TAG, "Loaded: " + collection.getTitle());
}
```

**Process**:
1. Get `{filesDir}/collections/` directory
2. Iterate through subdirectories
3. Load each collection with `loadCollectionFromFolder()`
4. Return list of Collections

##### loadCollectionFromFolder(Context context, File folder)
```java
public static Collection loadCollectionFromFolder(Context context, File folder)
```
Loads a single collection from a folder.

**Parameters**:
- `context`: Android Context
- `folder`: File object pointing to collection folder

**Returns**: Collection - Loaded collection or null if invalid

**Example**:
```java
File collectionFolder = new File(context.getFilesDir(), "collections/npub1abc...");
Collection collection = CollectionLoader.loadCollectionFromFolder(context, collectionFolder);
```

**Process**:
1. Parse `collection.js` → Collection metadata
2. Parse `extra/security.json` → CollectionSecurity
3. Parse `extra/tree-data.js` → List<CollectionFile>
4. Check ownership via CollectionKeysManager
5. Check favorite status via CollectionPreferences
6. Return populated Collection object

##### loadFilesFromTreeDataJs(Collection collection, File treeDataFile)
```java
public static void loadFilesFromTreeDataJs(Collection collection, File treeDataFile)
```
Parses tree-data.js and populates collection.files.

**Parameters**:
- `collection`: Collection object to populate
- `treeDataFile`: File object for tree-data.js

**Example**:
```java
File treeData = new File(collectionFolder, "extra/tree-data.js");
CollectionLoader.loadFilesFromTreeDataJs(collection, treeData);
List<CollectionFile> files = collection.getFiles();
```

##### scanFolder(Collection collection, File folder, String basePath)
```java
public static void scanFolder(Collection collection, File folder, String basePath)
```
Recursively scans a folder and populates file list.

**Parameters**:
- `collection`: Collection to populate
- `folder`: Folder to scan
- `basePath`: Base path for relative paths (usually "")

**Example**:
```java
File collectionRoot = new File(collectionPath);
CollectionLoader.scanFolder(collection, collectionRoot, "");
```

**Process**:
1. Iterate through folder contents
2. For each file/folder, create CollectionFile
3. Recursively scan subdirectories
4. Add to collection.files list

##### generateTreeDataJs(Collection collection, File collectionFolder)
```java
public static void generateTreeDataJs(Collection collection, File collectionFolder) throws IOException
```
Generates or updates tree-data.js with SHA1 hashes.

**Parameters**:
- `collection`: Collection object
- `collectionFolder`: Collection root folder

**Throws**: IOException - If file operations fail

**Example**:
```java
File collectionFolder = new File(collectionPath);
CollectionLoader.generateTreeDataJs(collection, collectionFolder);
```

**Process**:
1. Scan all files in collection
2. Calculate SHA1 hash for each file
3. Build tree-data.js structure
4. Write to `extra/tree-data.js`

---

### CollectionKeysManager

**Package**: `offgrid.geogram.util`

**Description**: Manages collection Nostr key pairs.

#### Static Methods

##### storeKeys(Context context, String npub, String nsec)
```java
public static void storeKeys(Context context, String npub, String nsec)
```
Stores a collection key pair.

**Parameters**:
- `context`: Android Context
- `npub`: Collection public key
- `nsec`: Collection private key

**Example**:
```java
String[] keys = NostrKeyGenerator.generateKeyPair();
String npub = keys[0];
String nsec = keys[1];
CollectionKeysManager.storeKeys(context, npub, nsec);
```

**Storage**: Saves to `collection_keys_config.json`

##### getNsec(Context context, String npub)
```java
public static String getNsec(Context context, String npub)
```
Retrieves the private key for a collection.

**Parameters**:
- `context`: Android Context
- `npub`: Collection public key

**Returns**: String - Private key (nsec) or null if not found

**Example**:
```java
String nsec = CollectionKeysManager.getNsec(context, collection.getId());
if (nsec != null) {
    // User owns this collection
}
```

##### isOwnedCollection(Context context, String npub)
```java
public static boolean isOwnedCollection(Context context, String npub)
```
Checks if user owns a collection.

**Parameters**:
- `context`: Android Context
- `npub`: Collection public key

**Returns**: boolean - true if nsec is stored

**Example**:
```java
if (CollectionKeysManager.isOwnedCollection(context, npub)) {
    // Show admin controls
}
```

##### getAllOwnedCollections(Context context)
```java
public static Map<String, JSONObject> getAllOwnedCollections(Context context)
```
Gets all owned collection key pairs.

**Parameters**:
- `context`: Android Context

**Returns**: Map<String, JSONObject> - Map of npub → key data

**Example**:
```java
Map<String, JSONObject> ownedCollections = CollectionKeysManager.getAllOwnedCollections(context);
for (String npub : ownedCollections.keySet()) {
    Log.d(TAG, "Owned collection: " + npub);
}
```

---

### CollectionPreferences

**Package**: `offgrid.geogram.util`

**Description**: Manages user preferences for collections.

#### Static Methods

##### setFavorite(Context context, String collectionId, boolean favorite)
```java
public static void setFavorite(Context context, String collectionId, boolean favorite)
```
Sets the favorite status for a collection.

**Parameters**:
- `context`: Android Context
- `collectionId`: Collection npub
- `favorite`: true to favorite, false to unfavorite

**Example**:
```java
CollectionPreferences.setFavorite(context, collection.getId(), true);
```

##### isFavorite(Context context, String collectionId)
```java
public static boolean isFavorite(Context context, String collectionId)
```
Checks if a collection is favorited.

**Parameters**:
- `context`: Android Context
- `collectionId`: Collection npub

**Returns**: boolean - true if favorited

**Example**:
```java
boolean favorited = CollectionPreferences.isFavorite(context, collection.getId());
favoriteIcon.setVisibility(favorited ? View.VISIBLE : View.GONE);
```

##### getAllFavorites(Context context)
```java
public static Set<String> getAllFavorites(Context context)
```
Gets all favorited collection IDs.

**Parameters**:
- `context`: Android Context

**Returns**: Set<String> - Set of favorited npubs

**Example**:
```java
Set<String> favorites = CollectionPreferences.getAllFavorites(context);
Log.d(TAG, "User has " + favorites.size() + " favorites");
```

---

## Related Documentation

- [Architecture](architecture.md) - System design
- [File Formats](file-formats.md) - Data formats
- [Security Model](security-model.md) - Security details
- [User Guide](user-guide.md) - User-facing features
