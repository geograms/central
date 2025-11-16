# Collection File Formats

This document specifies the file formats used in the Collections system.

## Overview

Collections use three primary metadata files:
1. **collection.js** - Main collection metadata
2. **security.json** - Security and permission configuration
3. **tree-data.js** - Complete file index with hashes

All metadata files use JSON format, with JavaScript files embedding JSON within a `window` variable assignment.

## File Locations

```
{collection_root}/
├── collection.js           # Required - Main metadata
├── extra/
│   ├── security.json       # Required - Security settings
│   └── tree-data.js        # Optional - File index
└── [user files and folders]
```

## 1. collection.js

### Format

JavaScript file containing a `window.COLLECTION_DATA` variable with JSON object.

```javascript
window.COLLECTION_DATA = {
  // JSON object here
}
```

### Full Schema

```javascript
window.COLLECTION_DATA = {
  "version": "1.0",

  "collection": {
    "id": "npub1...",                    // Nostr public key (bech32)
    "title": "My Collection",            // Display title
    "description": "A sample collection", // Description
    "created": "2025-11-16T10:30:00Z",   // ISO 8601 timestamp
    "updated": "2025-11-16T12:45:00Z",   // ISO 8601 timestamp
    "signature": ""                       // Future: Nostr signature
  },

  "statistics": {
    "files_count": 42,                   // Number of files
    "folders_count": 5,                  // Number of folders
    "total_size": 104857600,             // Total bytes
    "likes": 10,                         // Like count
    "dislikes": 2,                       // Dislike count
    "comments": 5,                       // Comment count
    "ratings": {
      "average": 4.5,                    // Average rating (0-5)
      "count": 8                         // Number of ratings
    },
    "downloads": 150,                    // Download count
    "last_computed": "2025-11-16T12:45:00Z"  // Last stats update
  },

  "views": {
    "total": 500,                        // Total view count
    "unique": 120,                       // Unique viewers
    "tags": []                           // Future: View tracking tags
  },

  "tags": ["documentation", "tutorial"], // Category tags

  "metadata": {
    "category": "general",               // Category (general/media/software/etc)
    "language": "en",                    // Primary language (ISO 639-1)
    "license": "CC-BY-4.0",              // License identifier
    "copyright": "Copyright 2025 Author", // Copyright notice
    "website": "https://example.com",    // Related website
    "contact": {
      "email": "author@example.com",     // Contact email
      "nostr": "npub1..."                // Contact Nostr pubkey
    },
    "donation_address": "",              // Bitcoin/Lightning address
    "attribution": "Created by Author",  // Attribution text
    "content_rating": "G",               // Content rating (G/PG/PG-13/R/NC-17)
    "mature_content": false              // Mature content flag
  }
}
```

### Field Descriptions

#### version
- **Type**: String
- **Required**: Yes
- **Description**: Schema version for compatibility
- **Current**: "1.0"

#### collection.id
- **Type**: String
- **Required**: Yes
- **Description**: Nostr public key in npub format (bech32 encoding)
- **Pattern**: `^npub1[a-z0-9]{58}$`
- **Example**: `"npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe"`

#### collection.title
- **Type**: String
- **Required**: Yes
- **Description**: Human-readable collection title
- **Max Length**: 100 characters
- **Example**: `"My Photo Album"`

#### collection.description
- **Type**: String
- **Required**: Yes (can be empty)
- **Description**: Detailed collection description
- **Max Length**: 1000 characters
- **Example**: `"Family photos from 2025 vacation"`

#### collection.created
- **Type**: String (ISO 8601)
- **Required**: Yes
- **Description**: Collection creation timestamp
- **Format**: `YYYY-MM-DDTHH:mm:ssZ`
- **Example**: `"2025-11-16T10:30:00Z"`

#### collection.updated
- **Type**: String (ISO 8601)
- **Required**: Yes
- **Description**: Last modification timestamp
- **Format**: `YYYY-MM-DDTHH:mm:ssZ`
- **Example**: `"2025-11-16T12:45:00Z"`

#### statistics.*
- **Type**: Numbers
- **Required**: No (defaults to 0)
- **Description**: Various statistics about collection usage
- **Notes**: Computed values, updated periodically

#### tags
- **Type**: Array of Strings
- **Required**: No
- **Description**: Categorization tags
- **Example**: `["photos", "vacation", "2025"]`

#### metadata.*
- **Type**: Various
- **Required**: No
- **Description**: Additional collection metadata
- **Notes**: All fields optional but recommended

### Minimal Example

```javascript
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    "id": "npub1abc123...",
    "title": "Quick Collection",
    "description": "",
    "created": "2025-11-16T10:00:00Z",
    "updated": "2025-11-16T10:00:00Z",
    "signature": ""
  },
  "statistics": {
    "files_count": 0,
    "folders_count": 0,
    "total_size": 0,
    "likes": 0,
    "dislikes": 0,
    "comments": 0,
    "ratings": { "average": 0, "count": 0 },
    "downloads": 0,
    "last_computed": "2025-11-16T10:00:00Z"
  },
  "views": {
    "total": 0,
    "unique": 0,
    "tags": []
  },
  "tags": [],
  "metadata": {
    "category": "general",
    "language": "en",
    "license": "",
    "copyright": "",
    "website": "",
    "contact": { "email": "", "nostr": "" },
    "donation_address": "",
    "attribution": "",
    "content_rating": "G",
    "mature_content": false
  }
}
```

## 2. security.json

### Format

Standard JSON file (not embedded in JavaScript).

### Full Schema

```json
{
  "version": "1.0",

  "visibility": "public",

  "permissions": {
    "public_read": true,
    "allow_submissions": false,
    "submission_requires_approval": true,
    "can_users_comment": true,
    "can_users_like": true,
    "can_users_dislike": true,
    "can_users_rate": true,
    "whitelisted_users": [],
    "blocked_users": []
  },

  "content_warnings": [],

  "age_restriction": {
    "enabled": false,
    "minimum_age": 0,
    "verification_required": false
  },

  "encryption": {
    "enabled": false,
    "method": null,
    "encrypted_files": []
  }
}
```

### Field Descriptions

#### version
- **Type**: String
- **Required**: Yes
- **Description**: Schema version
- **Current**: "1.0"

#### visibility
- **Type**: String (enum)
- **Required**: Yes
- **Values**: `"public"`, `"private"`, `"password"`, `"group"`
- **Description**: Access level
  - `public`: Anyone can access
  - `private`: Only owner can access
  - `password`: Password required (future)
  - `group`: Whitelist-based access

#### permissions.public_read
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow public read access
- **Note**: Usually `true` for public collections

#### permissions.allow_submissions
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow users to submit files to collection

#### permissions.submission_requires_approval
- **Type**: Boolean
- **Required**: Yes
- **Description**: Require owner approval for submissions
- **Note**: Only relevant if `allow_submissions` is true

#### permissions.can_users_comment
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow users to comment on collection

#### permissions.can_users_like
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow users to like collection

#### permissions.can_users_dislike
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow users to dislike collection

#### permissions.can_users_rate
- **Type**: Boolean
- **Required**: Yes
- **Description**: Allow users to rate collection (1-5 stars)

#### permissions.whitelisted_users
- **Type**: Array of Strings (npub)
- **Required**: Yes (can be empty)
- **Description**: List of allowed user npubs
- **Example**: `["npub1abc...", "npub1def..."]`

#### permissions.blocked_users
- **Type**: Array of Strings (npub)
- **Required**: Yes (can be empty)
- **Description**: List of blocked user npubs
- **Example**: `["npub1xyz..."]`

#### content_warnings
- **Type**: Array of Strings
- **Required**: Yes (can be empty)
- **Description**: Content warning tags
- **Example**: `["violence", "adult language"]`

#### age_restriction.enabled
- **Type**: Boolean
- **Required**: Yes
- **Description**: Enable age restriction

#### age_restriction.minimum_age
- **Type**: Number
- **Required**: Yes
- **Description**: Minimum age requirement
- **Example**: `18`

#### age_restriction.verification_required
- **Type**: Boolean
- **Required**: Yes
- **Description**: Require age verification (future)

#### encryption.enabled
- **Type**: Boolean
- **Required**: Yes
- **Description**: Enable encryption (future feature)

#### encryption.method
- **Type**: String or null
- **Required**: Yes
- **Description**: Encryption method (future)
- **Example**: `"aes-256-gcm"`

#### encryption.encrypted_files
- **Type**: Array of Strings
- **Required**: Yes (can be empty)
- **Description**: List of encrypted file paths (future)

### Example: Public Collection

```json
{
  "version": "1.0",
  "visibility": "public",
  "permissions": {
    "public_read": true,
    "allow_submissions": false,
    "submission_requires_approval": true,
    "can_users_comment": true,
    "can_users_like": true,
    "can_users_dislike": true,
    "can_users_rate": true,
    "whitelisted_users": [],
    "blocked_users": []
  },
  "content_warnings": [],
  "age_restriction": {
    "enabled": false,
    "minimum_age": 0,
    "verification_required": false
  },
  "encryption": {
    "enabled": false,
    "method": null,
    "encrypted_files": []
  }
}
```

### Example: Private Collection

```json
{
  "version": "1.0",
  "visibility": "private",
  "permissions": {
    "public_read": false,
    "allow_submissions": false,
    "submission_requires_approval": true,
    "can_users_comment": false,
    "can_users_like": false,
    "can_users_dislike": false,
    "can_users_rate": false,
    "whitelisted_users": [],
    "blocked_users": []
  },
  "content_warnings": [],
  "age_restriction": {
    "enabled": false,
    "minimum_age": 0,
    "verification_required": false
  },
  "encryption": {
    "enabled": false,
    "method": null,
    "encrypted_files": []
  }
}
```

### Example: Group Collection

```json
{
  "version": "1.0",
  "visibility": "group",
  "permissions": {
    "public_read": false,
    "allow_submissions": true,
    "submission_requires_approval": true,
    "can_users_comment": true,
    "can_users_like": true,
    "can_users_dislike": false,
    "can_users_rate": true,
    "whitelisted_users": [
      "npub1alice...",
      "npub1bob...",
      "npub1charlie..."
    ],
    "blocked_users": []
  },
  "content_warnings": [],
  "age_restriction": {
    "enabled": false,
    "minimum_age": 0,
    "verification_required": false
  },
  "encryption": {
    "enabled": false,
    "method": null,
    "encrypted_files": []
  }
}
```

## 3. tree-data.js

### Format

JavaScript file containing a `window.TREE_DATA` variable with JSON array.

```javascript
window.TREE_DATA = [
  // Array of file/folder objects
]
```

### Full Schema

```javascript
window.TREE_DATA = [
  {
    "path": "folder/subfolder/file.txt",  // Full path from collection root
    "name": "file.txt",                   // Display name
    "type": "file",                       // "file" or "directory"
    "size": 1024,                         // File size in bytes
    "mimeType": "text/plain",             // MIME type
    "hashes": {
      "sha1": "2fd4e1c67a..."             // SHA1 hash of file contents
    },
    "metadata": {
      "mime_type": "text/plain",          // Duplicate for compatibility
      "description": "",                  // Optional description
      "views": 0                          // View count
    }
  },
  {
    "path": "folder/subfolder",
    "name": "subfolder",
    "type": "directory"
  }
]
```

### Field Descriptions

#### path
- **Type**: String
- **Required**: Yes
- **Description**: Full path relative to collection root
- **Format**: Forward slashes, no leading slash
- **Example**: `"docs/readme.md"`

#### name
- **Type**: String
- **Required**: Yes
- **Description**: File or directory name (last component of path)
- **Example**: `"readme.md"`

#### type
- **Type**: String (enum)
- **Required**: Yes
- **Values**: `"file"`, `"directory"`
- **Description**: Entry type

#### size
- **Type**: Number
- **Required**: Yes for files, omit for directories
- **Description**: File size in bytes
- **Example**: `1024`

#### mimeType
- **Type**: String
- **Required**: Yes for files, omit for directories
- **Description**: MIME type of file
- **Example**: `"text/plain"`, `"image/jpeg"`, `"application/pdf"`

#### hashes.sha1
- **Type**: String (hex)
- **Required**: Yes for files, omit for directories
- **Description**: SHA1 hash of file contents (lowercase hex)
- **Length**: 40 characters
- **Example**: `"2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"`

#### metadata.mime_type
- **Type**: String
- **Required**: No
- **Description**: Duplicate of mimeType for compatibility

#### metadata.description
- **Type**: String
- **Required**: No
- **Description**: Optional file description

#### metadata.views
- **Type**: Number
- **Required**: No
- **Description**: View count for this file

### Example

```javascript
window.TREE_DATA = [
  {
    "path": "README.md",
    "name": "README.md",
    "type": "file",
    "size": 2048,
    "mimeType": "text/markdown",
    "hashes": {
      "sha1": "abc123def456..."
    },
    "metadata": {
      "mime_type": "text/markdown"
    }
  },
  {
    "path": "docs",
    "name": "docs",
    "type": "directory"
  },
  {
    "path": "docs/guide.pdf",
    "name": "guide.pdf",
    "type": "file",
    "size": 524288,
    "mimeType": "application/pdf",
    "hashes": {
      "sha1": "789xyz012abc..."
    },
    "metadata": {
      "mime_type": "application/pdf",
      "description": "User guide for the application"
    }
  }
]
```

### Notes

- All directories should be listed before their contents for efficient parsing
- Paths use forward slashes (/) regardless of platform
- SHA1 hashes enable integrity verification and deduplication
- Empty folders should still have a directory entry

## 4. collection_keys_config.json

### Format

Standard JSON file stored in app files directory (not in collection folder).

### Location

`{appFilesDir}/collection_keys_config.json`

### Schema

```json
{
  "npub1abc...": {
    "npub": "npub1abc...",
    "nsec": "nsec1xyz...",
    "created": 1700000000000
  },
  "npub1def...": {
    "npub": "npub1def...",
    "nsec": "nsec1uvw...",
    "created": 1700000001000
  }
}
```

### Field Descriptions

#### Top-level keys
- **Type**: String (npub)
- **Description**: Collection ID (npub) as key

#### npub
- **Type**: String
- **Required**: Yes
- **Description**: Nostr public key in npub format

#### nsec
- **Type**: String
- **Required**: Yes
- **Description**: Nostr private key in nsec format
- **Security**: Keep confidential!

#### created
- **Type**: Number
- **Required**: Yes
- **Description**: Unix timestamp (milliseconds) when keys were created

### Example

```json
{
  "npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe": {
    "npub": "npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe",
    "nsec": "nsec1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaah5s3fh",
    "created": 1700000000000
  }
}
```

## Parsing Guidelines

### JavaScript File Parsing

To extract JSON from JavaScript files:

1. Read file as string
2. Find the variable assignment (e.g., `window.COLLECTION_DATA = `)
3. Extract everything after `=` and before the final `}`
4. Parse the extracted JSON

Example code pattern:
```java
String content = readFileAsString(file);
int startIndex = content.indexOf("window.COLLECTION_DATA = ") + 25;
int endIndex = content.lastIndexOf("}");
String jsonString = content.substring(startIndex, endIndex + 1);
JSONObject json = new JSONObject(jsonString);
```

### Error Handling

- Missing files: Use sensible defaults
- Malformed JSON: Skip collection or use empty values
- Invalid npub: Reject collection
- Missing required fields: Use defaults or reject

### Validation

Before accepting a collection:
1. Verify npub format (bech32, 63 characters)
2. Validate JSON structure
3. Check required fields are present
4. Verify file references in tree-data.js exist on disk
5. Validate SHA1 hashes match file contents (optional, expensive)

## Version Compatibility

Current version: 1.0

Future versions should:
- Maintain backward compatibility
- Add new optional fields
- Deprecate fields gradually
- Use version field to handle differences

## Related Documentation

- [Architecture](architecture.md) - System design
- [Security Model](security-model.md) - Security details
- [Examples](examples/) - Sample files
- [Schemas](schemas/) - JSON schemas for validation
