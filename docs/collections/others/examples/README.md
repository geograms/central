# Collection Examples

This directory contains example collection metadata files demonstrating various configurations.

## Files

### collection.js
Complete example of a collection metadata file with all fields populated.

**Use Case**: Public documentation collection with full metadata

**Features**:
- Complete metadata fields
- Statistics populated
- Tags included
- Contact and license information

### security.json
Default public collection security configuration.

**Use Case**: Publicly accessible collection with full user interaction

**Settings**:
- Public visibility
- Read access for all
- Comments, likes, dislikes, ratings enabled
- No submissions allowed

### security-private.json
Private collection security configuration.

**Use Case**: Personal files, private backups

**Settings**:
- Private visibility
- No public access
- All user interactions disabled
- Owner-only access

### security-group.json
Group collection with whitelisted users.

**Use Case**: Team collaboration, private workgroup

**Settings**:
- Group visibility
- Whitelist of allowed user npubs
- Submissions enabled with approval
- User interactions enabled (except dislikes)

### tree-data.js
Example file tree with various file types.

**Use Case**: Documentation collection with folders and files

**Contents**:
- Markdown files
- JavaScript examples
- Images
- License file
- Multiple folders
- SHA1 hashes for all files

## Usage

### Creating a Collection from Examples

1. **Copy example files**:
```bash
mkdir -p collections/your-collection/extra/
cp examples/collection.js collections/your-collection/
cp examples/security.json collections/your-collection/extra/
```

2. **Customize metadata**:
   - Edit `collection.js` with your title, description
   - Generate new npub/nsec key pair
   - Update timestamps

3. **Add your files**:
   - Add your files to the collection folder
   - Run collection scanner to generate tree-data.js

4. **Customize security**:
   - Choose visibility level (public/private/group)
   - Set permissions as needed
   - Add whitelisted users if group visibility

### Minimal Collection

For a minimal collection, you only need:

```javascript
// collection.js (minimal)
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    "id": "npub1...",
    "title": "My Collection",
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
  "views": { "total": 0, "unique": 0, "tags": [] },
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

```json
// extra/security.json (minimal)
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

## Validation

Validate your collection files using the JSON schemas in `../schemas/`:

```bash
# Validate against schema (requires JSON schema validator)
jsonschema -i collection.js ../schemas/collection-schema.json
jsonschema -i extra/security.json ../schemas/security-schema.json
jsonschema -i extra/tree-data.js ../schemas/tree-data-schema.json
```

## Related Documentation

- [File Formats](../file-formats.md) - Detailed format specifications
- [Security Model](../security-model.md) - Security configuration guide
- [Metadata Specification](../metadata-specification.md) - Metadata best practices
- [Schemas](../schemas/) - JSON schemas for validation
