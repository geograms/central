# Collection JSON Schemas

This directory contains JSON Schema definitions for validating Geogram collection metadata files.

## Schemas

### collection-schema.json
Validates the `collection.js` metadata file structure.

**Validates**:
- Schema version
- Collection identification (npub)
- Title and description
- Timestamps (created, updated)
- Statistics (files, size, engagement)
- Views tracking
- Tags
- Extended metadata (license, contact, etc.)

**Usage**:
```bash
# Using ajv-cli
ajv validate -s collection-schema.json -d ../examples/collection.js

# Using jsonschema (Python)
jsonschema -i ../examples/collection.js collection-schema.json

# Programmatically (JavaScript)
const Ajv = require('ajv');
const ajv = new Ajv();
const validate = ajv.compile(collectionSchema);
const valid = validate(collectionData);
```

### security-schema.json
Validates the `extra/security.json` security configuration file.

**Validates**:
- Schema version
- Visibility level (public/private/password/group)
- Permission settings
- Whitelisted and blocked users
- Content warnings
- Age restrictions
- Encryption settings (future)

**Usage**:
```bash
ajv validate -s security-schema.json -d ../examples/security.json
```

### tree-data-schema.json
Validates the `extra/tree-data.js` file index structure.

**Validates**:
- File entries (path, name, size, type, mime type, hashes)
- Directory entries (path, name, type)
- SHA1 hash format
- Optional metadata fields

**Usage**:
```bash
ajv validate -s tree-data-schema.json -d ../examples/tree-data.js
```

## Installation

### JavaScript/Node.js

```bash
# Install ajv (JSON Schema validator)
npm install ajv ajv-cli

# Validate files
ajv validate -s collection-schema.json -d collection.js
```

### Python

```bash
# Install jsonschema
pip install jsonschema

# Validate files
jsonschema -i collection.js collection-schema.json
```

### Java

```xml
<!-- Add dependency to pom.xml -->
<dependency>
  <groupId>com.github.java-json-tools</groupId>
  <artifactId>json-schema-validator</artifactId>
  <version>2.2.14</version>
</dependency>
```

```java
// Validate in Java
import com.github.fge.jsonschema.main.JsonSchema;
import com.github.fge.jsonschema.main.JsonSchemaFactory;

JsonSchemaFactory factory = JsonSchemaFactory.byDefault();
JsonSchema schema = factory.getJsonSchema("collection-schema.json");
ProcessingReport report = schema.validate(jsonData);
boolean valid = report.isSuccess();
```

## Validation Examples

### Valid Collection

```javascript
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    "id": "npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe",
    "title": "Example Collection",
    "description": "A valid collection",
    "created": "2025-11-16T10:00:00Z",
    "updated": "2025-11-16T10:00:00Z",
    "signature": ""
  },
  // ... rest of required fields
}
```

### Invalid Collection (Missing Required Field)

```javascript
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    // MISSING: "id" field
    "title": "Example Collection",
    "description": "Invalid - missing id",
    "created": "2025-11-16T10:00:00Z",
    "updated": "2025-11-16T10:00:00Z",
    "signature": ""
  }
}
```

**Error**: `Required property 'id' is missing`

### Invalid Collection (Wrong Type)

```javascript
window.COLLECTION_DATA = {
  "version": "1.0",
  "collection": {
    "id": "npub1abc...",
    "title": 12345,  // INVALID: should be string
    "description": "",
    "created": "2025-11-16T10:00:00Z",
    "updated": "2025-11-16T10:00:00Z",
    "signature": ""
  }
}
```

**Error**: `Instance type (integer) does not match any allowed primitive type (allowed: ["string"])`

## Schema Versioning

Current schema version: **1.0**

### Version Compatibility

- **1.0**: Initial release
- Future versions will maintain backward compatibility
- Breaking changes will increment major version

### Upgrading Schemas

When schema version changes:

1. Update `version` field in metadata files
2. Add new required fields with defaults
3. Migrate deprecated fields
4. Validate against new schema

## Common Validation Errors

### Error: Invalid npub format

**Cause**: npub doesn't match required pattern

**Fix**: Ensure npub is exactly 63 characters, starts with "npub1", and contains only lowercase letters and numbers

### Error: Missing required property

**Cause**: Required field is not present in JSON

**Fix**: Add the missing field with appropriate value

### Error: Type mismatch

**Cause**: Field value is wrong type (e.g., number instead of string)

**Fix**: Convert value to correct type

### Error: Value out of range

**Cause**: Numeric value exceeds min/max constraints

**Fix**: Adjust value to be within valid range

### Error: Invalid date format

**Cause**: Timestamp is not in ISO 8601 format

**Fix**: Use format `YYYY-MM-DDTHH:mm:ssZ` (e.g., `2025-11-16T10:00:00Z`)

## Custom Validation

For additional validation beyond schema:

### File Existence Check

```java
// Verify files in tree-data.js actually exist
for (CollectionFile file : files) {
    File diskFile = new File(collectionPath, file.getPath());
    if (!diskFile.exists()) {
        errors.add("File not found: " + file.getPath());
    }
}
```

### Hash Verification

```java
// Verify SHA1 hashes match file contents
String expectedHash = file.getHashes().get("sha1");
String actualHash = calculateSHA1(diskFile);
if (!expectedHash.equals(actualHash)) {
    errors.add("Hash mismatch for: " + file.getPath());
}
```

### Timestamp Consistency

```java
// Verify updated >= created
Date created = parseDate(collection.getCreated());
Date updated = parseDate(collection.getUpdated());
if (updated.before(created)) {
    errors.add("Updated timestamp is before created timestamp");
}
```

## Continuous Validation

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Validate all collection metadata files
for file in collections/*/collection.js; do
  ajv validate -s schemas/collection-schema.json -d "$file" || exit 1
done

for file in collections/*/extra/security.json; do
  ajv validate -s schemas/security-schema.json -d "$file" || exit 1
done
```

### CI/CD Integration

```yaml
# .github/workflows/validate-collections.yml
name: Validate Collections

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install ajv
        run: npm install -g ajv-cli
      - name: Validate collections
        run: |
          find collections -name "collection.js" -exec ajv validate -s schemas/collection-schema.json -d {} \;
          find collections -name "security.json" -exec ajv validate -s schemas/security-schema.json -d {} \;
```

## Related Documentation

- [File Formats](../file-formats.md) - Detailed format specifications
- [Examples](../examples/) - Example files to validate
- [Metadata Specification](../metadata-specification.md) - Metadata guidelines
- [Architecture](../architecture.md) - How validation fits into the system
