# Collection Security Model

This document describes the security architecture and permission system for Geogram Collections.

## Security Overview

Collections implement a multi-layered security model:
1. **Cryptographic Identity**: Nostr key pairs for ownership
2. **Access Control**: Visibility levels and permissions
3. **User Management**: Whitelists and blocklists
4. **Content Safety**: Age restrictions and content warnings
5. **Encryption**: File encryption (planned feature)

## Cryptographic Identity

### Nostr Key Pairs

Each collection is identified by a Nostr key pair:
- **npub** (public key): Collection identifier, publicly shareable
- **nsec** (private key): Owner's secret key, proves ownership

#### Key Generation

Keys are generated when creating a collection:
```
NostrKeyGenerator.generateKeyPair()
  ↓
Returns: (npub, nsec)
  ↓
Store nsec in collection_keys_config.json
Use npub as collection ID and folder name
```

#### Key Format

- **npub**: Bech32-encoded public key, 63 characters
  - Prefix: `npub1`
  - Example: `npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq3z0qwe`

- **nsec**: Bech32-encoded private key, 63 characters
  - Prefix: `nsec1`
  - Example: `nsec1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaah5s3fh`

### Ownership Model

Collection ownership is determined by possession of the nsec:
- **Owned Collection**: User has nsec stored locally
- **Unowned Collection**: User only has npub (read-only or shared)

Owners can:
- Modify collection metadata
- Add/remove files
- Change security settings
- Delete the collection
- Sign updates (future)

Non-owners can:
- View collection (if permitted)
- Download files (if permitted)
- Interact (like, comment, rate) if permitted
- Submit files (if allowed and approved)

### Key Storage

Private keys are stored securely:
- **Location**: `{appFilesDir}/collection_keys_config.json`
- **Format**: JSON mapping npub → {npub, nsec, created}
- **Protection**: App-private directory, not backed up by default
- **Access**: Only Geogram app can access

**Warning**: Lost nsec = lost collection ownership!

## Access Control Levels

Collections support four visibility levels defined in `security.json`:

### 1. Public Collections

**Configuration**:
```json
{
  "visibility": "public",
  "permissions": {
    "public_read": true
  }
}
```

**Behavior**:
- Anyone can view collection metadata
- Anyone can browse files
- Anyone can download files
- No authentication required
- Suitable for open content distribution

**Use Cases**:
- Open-source software packages
- Public documentation
- Creative Commons media
- Educational materials

### 2. Private Collections

**Configuration**:
```json
{
  "visibility": "private",
  "permissions": {
    "public_read": false
  }
}
```

**Behavior**:
- Only owner can access
- Other users cannot view or download
- Collection hidden from remote browsers
- Maximum privacy

**Use Cases**:
- Personal files and backups
- Private notes and documents
- Confidential information
- Work-in-progress content

### 3. Password-Protected Collections

**Configuration**:
```json
{
  "visibility": "password",
  "permissions": {
    "public_read": false
  }
}
```

**Status**: Planned feature, not yet implemented

**Intended Behavior**:
- Requires password to access
- Password stored as hash (bcrypt/argon2)
- Password can be shared out-of-band
- Good balance of security and convenience

**Use Cases**:
- Shared family archives
- Team collaboration
- Community resources
- Semi-private distribution

### 4. Group Collections

**Configuration**:
```json
{
  "visibility": "group",
  "permissions": {
    "public_read": false,
    "whitelisted_users": [
      "npub1alice...",
      "npub1bob..."
    ]
  }
}
```

**Behavior**:
- Only whitelisted npubs can access
- Whitelist managed by owner
- Fine-grained access control
- Members can be added/removed

**Use Cases**:
- Private workgroups
- Exclusive content for subscribers
- Family or friend groups
- Controlled distribution

## Permission System

The `permissions` object in `security.json` controls user interactions:

### Read Permissions

#### public_read
- **Type**: Boolean
- **Default**: true for public, false otherwise
- **Description**: Allow unauthenticated read access
- **Effect**: Controls whether files can be viewed/downloaded

### Submission Permissions

#### allow_submissions
- **Type**: Boolean
- **Default**: false
- **Description**: Allow users to submit files to collection
- **Requirements**: User must be authenticated (future)

#### submission_requires_approval
- **Type**: Boolean
- **Default**: true
- **Description**: Require owner approval for submitted files
- **Effect**: Submissions go to pending queue vs. immediate addition

**Submission Workflow** (Future):
```
User submits file
  ↓
submission_requires_approval = true?
  ↓ Yes                    ↓ No
Pending queue         Added immediately
  ↓
Owner reviews
  ↓
Approve → Add to collection
Reject → Delete submission
```

### Interaction Permissions

#### can_users_comment
- **Type**: Boolean
- **Default**: true
- **Description**: Allow users to comment on collection
- **Status**: Planned feature

#### can_users_like
- **Type**: Boolean
- **Default**: true
- **Description**: Allow users to like collection
- **Effect**: Increments like counter

#### can_users_dislike
- **Type**: Boolean
- **Default**: true
- **Description**: Allow users to dislike collection
- **Effect**: Increments dislike counter

#### can_users_rate
- **Type**: Boolean
- **Default**: true
- **Description**: Allow users to rate collection (1-5 stars)
- **Effect**: Updates average rating and count

### User Lists

#### whitelisted_users
- **Type**: Array of npub strings
- **Default**: []
- **Description**: List of allowed users for group collections
- **Format**: `["npub1...", "npub1..."]`
- **Check**: User's npub must be in list to access

#### blocked_users
- **Type**: Array of npub strings
- **Default**: []
- **Description**: List of banned users
- **Format**: `["npub1...", "npub1..."]`
- **Check**: Access denied if user's npub in list
- **Priority**: Block list overrides whitelist

### Permission Evaluation

Access is granted if:
```
1. User is owner (has nsec)
   OR
2. visibility = "public" AND public_read = true
   OR
3. visibility = "group" AND user.npub IN whitelisted_users
   OR
4. visibility = "password" AND correct password provided (future)

AND

5. user.npub NOT IN blocked_users
```

## Content Safety

### Content Warnings

**Configuration**:
```json
{
  "content_warnings": ["violence", "adult language", "flashing lights"]
}
```

**Behavior**:
- Display warnings before showing collection
- Allow users to acknowledge and proceed
- Help users make informed decisions

**Common Tags**:
- `violence`
- `adult language`
- `sexual content`
- `flashing lights`
- `gore`
- `drug use`

### Age Restrictions

**Configuration**:
```json
{
  "age_restriction": {
    "enabled": true,
    "minimum_age": 18,
    "verification_required": false
  }
}
```

#### age_restriction.enabled
- **Type**: Boolean
- **Default**: false
- **Description**: Enable age gate

#### age_restriction.minimum_age
- **Type**: Number
- **Default**: 0
- **Description**: Minimum age requirement
- **Common Values**: 13, 16, 18, 21

#### age_restriction.verification_required
- **Type**: Boolean
- **Default**: false
- **Description**: Require age verification (future)
- **Status**: Planned feature

**Behavior**:
```
User attempts to access collection
  ↓
age_restriction.enabled = true?
  ↓ Yes
Show age gate dialog
  ↓
User confirms age >= minimum_age
  ↓
verification_required = true?
  ↓ Yes                    ↓ No
Verify via ID/payment    Accept on honor
  ↓
Grant access
```

### Content Rating

**Configuration** (in collection.js):
```json
{
  "metadata": {
    "content_rating": "PG-13",
    "mature_content": true
  }
}
```

**Ratings** (similar to MPAA):
- **G**: General audiences
- **PG**: Parental guidance suggested
- **PG-13**: Parents strongly cautioned
- **R**: Restricted
- **NC-17**: Adults only

## Encryption (Planned)

**Configuration**:
```json
{
  "encryption": {
    "enabled": true,
    "method": "aes-256-gcm",
    "encrypted_files": [
      "sensitive/data.pdf",
      "private/notes.txt"
    ]
  }
}
```

**Status**: Planned feature, not yet implemented

### Planned Features

#### File Encryption
- **Algorithm**: AES-256-GCM
- **Key Derivation**: From password or nsec
- **Scope**: Individual files or entire collection
- **Format**: Encrypted files stored with `.encrypted` extension

#### Encryption Modes

**1. Password-Based Encryption**
- User provides password
- Key derived using PBKDF2 or Argon2
- Password not stored (only hash for verification)
- User must remember password

**2. Key-Based Encryption**
- Derived from collection nsec
- Automatic for owned collections
- Shared via secure channel for group access

**3. Hybrid Encryption**
- Symmetric key encrypts files (fast)
- Asymmetric key encrypts symmetric key (secure)
- Support for multiple recipients

### Encryption Workflow (Planned)

```
User enables encryption
  ↓
Select encryption method and password/key
  ↓
For each file to encrypt:
  ↓
  Generate random IV
  ↓
  Encrypt file with AES-256-GCM
  ↓
  Store encrypted file as {name}.encrypted
  ↓
  Add to encrypted_files list
  ↓
Update security.json
```

## Security Best Practices

### For Collection Owners

1. **Backup nsec**: Store private key in secure location
2. **Use Strong Passwords**: If password protection is enabled
3. **Minimize Whitelists**: Only add trusted users
4. **Review Submissions**: Carefully vet submitted files
5. **Monitor Blocklist**: Add problematic users promptly
6. **Set Content Ratings**: Accurately reflect content maturity
7. **Use Content Warnings**: Warn about potentially disturbing content

### For Collection Consumers

1. **Verify npub**: Ensure collection is from expected source
2. **Check Signatures**: Verify signed collections (future)
3. **Review Permissions**: Understand what access you're granting
4. **Heed Warnings**: Pay attention to content warnings
5. **Scan Downloads**: Check files for malware
6. **Respect Age Gates**: Don't bypass age restrictions

### For Developers

1. **Validate Input**: Sanitize all user input
2. **Secure Key Storage**: Use platform key storage APIs
3. **Encrypt at Rest**: Consider encrypting entire app database
4. **Audit Logs**: Log access and modifications
5. **Rate Limiting**: Prevent brute-force attacks
6. **Verify Signatures**: Implement signature verification
7. **Sandboxing**: Isolate collection file access

## Attack Vectors and Mitigations

### 1. Key Theft

**Attack**: Attacker steals nsec from device
**Impact**: Full collection ownership
**Mitigation**:
- Store nsec in app-private directory
- Encrypt nsec with device credentials
- Use Android Keystore for key encryption
- Require biometric authentication for key access

### 2. Malicious Files

**Attack**: Attacker shares collection with malware
**Impact**: Device compromise
**Mitigation**:
- Scan files before opening
- Warn users about executable file types
- Sandbox file access
- Use Android Storage Access Framework

### 3. Metadata Tampering

**Attack**: Attacker modifies collection.js or security.json
**Impact**: Misleading metadata, changed permissions
**Mitigation**:
- Implement signature verification (planned)
- Hash metadata files
- Verify signatures against npub
- Warn on signature mismatch

### 4. Whitelist Bypass

**Attack**: Attacker forges npub to gain access
**Impact**: Unauthorized access to group collections
**Mitigation**:
- Verify npub format and validity
- Require signature for authentication (future)
- Implement challenge-response authentication
- Log access attempts

### 5. Denial of Service

**Attack**: Attacker creates massive collection
**Impact**: Device storage exhaustion, app crash
**Mitigation**:
- Limit collection size
- Limit file count
- Implement quotas
- Lazy loading of file trees

### 6. Privacy Leaks

**Attack**: Metadata reveals private information
**Impact**: Privacy compromise
**Mitigation**:
- Minimize metadata collection
- Allow anonymous statistics
- Encrypt sensitive metadata
- Clear separation of public/private data

## Signature Verification (Planned)

### Purpose
Verify that collection metadata hasn't been tampered with and originates from the claimed owner.

### Mechanism

1. **Collection Creation**:
   ```
   Create collection.js
     ↓
   Stringify JSON metadata
     ↓
   Sign with nsec using Schnorr signature
     ↓
   Add signature to collection.signature field
   ```

2. **Collection Verification**:
   ```
   Load collection.js
     ↓
   Extract signature field
     ↓
   Remove signature from JSON
     ↓
   Verify signature against npub
     ↓
   signature valid?
     ↓ Yes              ↓ No
   Trust metadata    Warn user / reject
   ```

### Signature Format

**In collection.js**:
```javascript
{
  "collection": {
    "id": "npub1...",
    "signature": "a1b2c3d4e5f6..."  // Hex-encoded Schnorr signature
  }
}
```

**Signature Data** (what is signed):
```json
{
  "id": "npub1...",
  "title": "...",
  "description": "...",
  "created": "...",
  "updated": "..."
  // signature field excluded from signed data
}
```

### Implementation

```java
// Signing
String metadataJson = collectionToJsonWithoutSignature(collection);
byte[] signature = NostrSigner.sign(metadataJson, nsec);
collection.signature = bytesToHex(signature);

// Verification
String metadataJson = collectionToJsonWithoutSignature(collection);
byte[] signature = hexToBytes(collection.signature);
boolean valid = NostrSigner.verify(metadataJson, signature, npub);
if (!valid) {
  throw new SecurityException("Invalid collection signature");
}
```

## Future Enhancements

### Planned Security Features

1. **Multi-Signature**: Require multiple owners to approve changes
2. **Time-Limited Access**: Temporary whitelist entries
3. **Access Logs**: Track who accessed what and when
4. **Revocation Lists**: Centralized list of compromised collections
5. **Hardware Security**: Use secure enclaves for key storage
6. **Zero-Knowledge Proofs**: Prove ownership without revealing nsec
7. **Decentralized Identity**: Integrate with DID standards

### Authentication Methods (Future)

1. **Nostr NIP-04**: Encrypted direct messages for key exchange
2. **Nostr NIP-26**: Delegated event signing
3. **Lightning Auth**: Authenticate via Lightning Network
4. **FIDO2/WebAuthn**: Hardware token authentication

## Compliance Considerations

### GDPR (Europe)
- User data minimization
- Right to be forgotten
- Data portability
- Consent management

### COPPA (USA)
- Age verification for users under 13
- Parental consent mechanisms
- Privacy policy requirements

### DMCA (USA)
- Takedown procedures
- Counter-notice process
- Repeat infringer policy

### Content Regulation
- Illegal content reporting
- Cooperation with law enforcement
- Age-appropriate content controls

## Related Documentation

- [Architecture](architecture.md) - System design
- [File Formats](file-formats.md) - security.json specification
- [API Reference](api-reference.md) - Security API methods
- [User Guide](user-guide.md) - Security settings UI
