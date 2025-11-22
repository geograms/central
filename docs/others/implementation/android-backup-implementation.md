# Android Backup Implementation

**Version**: 1.0
**Last Updated**: 2025-11-16
**Status**: Implemented

---

## Overview

The backup system allows users to export and import their Geogram data as encrypted ZIP archives. This enables data portability, device migration, and disaster recovery while maintaining privacy and security.

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────┐
│         BackupFragment (UI)             │
├─────────────────────────────────────────┤
│         BackupManager                   │
│  ┌────────────┐  ┌─────────────────┐   │
│  │ DataExport │  │ DataImport      │   │
│  └────────────┘  └─────────────────┘   │
├─────────────────────────────────────────┤
│         EncryptionManager               │
├─────────────────────────────────────────┤
│         Storage Access Framework        │
└─────────────────────────────────────────┘
```

### Key Components

**1. BackupManager.java**
- Main coordinator for backup operations
- Handles export and import workflows
- Manages encryption and file operations

**2. DataExport.java**
- Serializes app data to JSON format
- Creates ZIP archives with metadata
- Handles large file chunking

**3. DataImport.java**
- Validates and parses backup archives
- Restores data with conflict resolution
- Provides progress callbacks

**4. EncryptionManager.java**
- AES-256 encryption for sensitive data
- Key derivation from user passphrase
- Secure random key generation

---

## Data Model

### Backup Archive Structure

```
backup_2025-11-16.zip
├── manifest.json          # Archive metadata
├── data/
│   ├── settings.json      # App settings
│   ├── identity.json      # User identity/keys
│   ├── collections.json   # Collection metadata
│   └── messages.json      # Message history
├── collections/           # Collection files
│   └── mycollection.zip
└── checksums.sha256       # File integrity
```

### Manifest Format

```json
{
  "version": "1.0",
  "timestamp": "2025-11-16T10:30:00Z",
  "appVersion": "1.0.0",
  "deviceId": "device-uuid",
  "components": {
    "settings": true,
    "identity": true,
    "collections": true,
    "messages": false
  },
  "encryption": {
    "algorithm": "AES-256-GCM",
    "keyDerivation": "PBKDF2",
    "iterations": 10000
  }
}
```

---

## Implementation

### BackupManager.java

```java
package offgrid.geogram.util;

import android.content.Context;
import android.net.Uri;
import java.io.File;
import java.util.List;

public class BackupManager {

    private Context context;
    private EncryptionManager encryption;
    private DataExport exporter;
    private DataImport importer;

    public BackupManager(Context context) {
        this.context = context;
        this.encryption = new EncryptionManager();
        this.exporter = new DataExport(context);
        this.importer = new DataImport(context);
    }

    /**
     * Export data to encrypted ZIP archive
     */
    public void exportBackup(Uri destinationUri, String passphrase,
                           List<BackupComponent> components,
                           BackupProgressCallback callback) throws Exception {

        // Generate encryption key from passphrase
        byte[] key = encryption.deriveKey(passphrase);

        // Create temporary working directory
        File tempDir = createTempDirectory();

        try {
            // Export data components
            for (BackupComponent component : components) {
                callback.onProgress(component, 0);
                exporter.exportComponent(component, tempDir, key);
                callback.onProgress(component, 100);
            }

            // Create manifest
            createManifest(tempDir, components);

            // Create ZIP archive
            createEncryptedZip(tempDir, destinationUri, key, callback);

        } finally {
            // Clean up temporary files
            deleteTempDirectory(tempDir);
        }
    }

    /**
     * Import data from backup archive
     */
    public void importBackup(Uri sourceUri, String passphrase,
                           List<BackupComponent> components,
                           BackupProgressCallback callback) throws Exception {

        // Generate encryption key from passphrase
        byte[] key = encryption.deriveKey(passphrase);

        // Create temporary working directory
        File tempDir = createTempDirectory();

        try {
            // Extract and decrypt ZIP archive
            extractEncryptedZip(sourceUri, tempDir, key);

            // Validate manifest
            BackupManifest manifest = validateManifest(tempDir);

            // Import data components
            for (BackupComponent component : components) {
                if (manifest.hasComponent(component)) {
                    callback.onProgress(component, 0);
                    importer.importComponent(component, tempDir, key);
                    callback.onProgress(component, 100);
                }
            }

        } finally {
            // Clean up temporary files
            deleteTempDirectory(tempDir);
        }
    }

    // Helper methods...
    private File createTempDirectory() { /* ... */ }
    private void createManifest(File tempDir, List<BackupComponent> components) { /* ... */ }
    private void createEncryptedZip(File sourceDir, Uri destinationUri, byte[] key, BackupProgressCallback callback) { /* ... */ }
    private void extractEncryptedZip(Uri sourceUri, File destinationDir, byte[] key) { /* ... */ }
    private BackupManifest validateManifest(File tempDir) { /* ... */ }
    private void deleteTempDirectory(File dir) { /* ... */ }
}
```

### DataExport.java

```java
package offgrid.geogram.util;

import android.content.Context;
import com.google.gson.Gson;
import java.io.File;
import java.io.FileWriter;

public class DataExport {

    private Context context;
    private Gson gson;

    public DataExport(Context context) {
        this.context = context;
        this.gson = new Gson();
    }

    /**
     * Export a data component to JSON file
     */
    public void exportComponent(BackupComponent component, File destinationDir,
                              byte[] encryptionKey) throws Exception {

        File componentFile = new File(destinationDir, component.getFilename());

        switch (component) {
            case SETTINGS:
                exportSettings(componentFile);
                break;
            case IDENTITY:
                exportIdentity(componentFile, encryptionKey);
                break;
            case COLLECTIONS:
                exportCollections(componentFile);
                break;
            case MESSAGES:
                exportMessages(componentFile, encryptionKey);
                break;
        }
    }

    private void exportSettings(File file) throws Exception {
        // Export app settings to JSON
        SettingsData settings = loadSettingsFromDatabase();
        writeJsonToFile(settings, file);
    }

    private void exportIdentity(File file, byte[] key) throws Exception {
        // Export identity with encryption
        IdentityData identity = loadIdentityFromDatabase();
        String json = gson.toJson(identity);
        byte[] encrypted = encryptData(json.getBytes(), key);
        writeBytesToFile(encrypted, file);
    }

    private void exportCollections(File file) throws Exception {
        // Export collection metadata
        List<CollectionInfo> collections = loadCollectionsFromDatabase();
        writeJsonToFile(collections, file);
    }

    private void exportMessages(File file, byte[] key) throws Exception {
        // Export messages with encryption
        List<MessageData> messages = loadMessagesFromDatabase();
        String json = gson.toJson(messages);
        byte[] encrypted = encryptData(json.getBytes(), key);
        writeBytesToFile(encrypted, file);
    }

    // Helper methods...
    private void writeJsonToFile(Object data, File file) throws Exception {
        try (FileWriter writer = new FileWriter(file)) {
            gson.toJson(data, writer);
        }
    }

    private byte[] encryptData(byte[] data, byte[] key) throws Exception {
        return encryption.encrypt(data, key);
    }
}
```

### DataImport.java

```java
package offgrid.geogram.util;

import android.content.Context;
import com.google.gson.Gson;
import java.io.File;

public class DataImport {

    private Context context;
    private Gson gson;

    public DataImport(Context context) {
        this.context = context;
        this.gson = new Gson();
    }

    /**
     * Import a data component from backup file
     */
    public void importComponent(BackupComponent component, File sourceDir,
                              byte[] encryptionKey) throws Exception {

        File componentFile = new File(sourceDir, component.getFilename());

        if (!componentFile.exists()) {
            throw new Exception("Component file not found: " + componentFile.getName());
        }

        switch (component) {
            case SETTINGS:
                importSettings(componentFile);
                break;
            case IDENTITY:
                importIdentity(componentFile, encryptionKey);
                break;
            case COLLECTIONS:
                importCollections(componentFile);
                break;
            case MESSAGES:
                importMessages(componentFile, encryptionKey);
                break;
        }
    }

    private void importSettings(File file) throws Exception {
        SettingsData settings = readJsonFromFile(file, SettingsData.class);
        saveSettingsToDatabase(settings);
    }

    private void importIdentity(File file, byte[] key) throws Exception {
        byte[] encrypted = readBytesFromFile(file);
        byte[] decrypted = decryptData(encrypted, key);
        String json = new String(decrypted);
        IdentityData identity = gson.fromJson(json, IdentityData.class);
        saveIdentityToDatabase(identity);
    }

    private void importCollections(File file) throws Exception {
        List<CollectionInfo> collections = readJsonFromFile(file, List.class);
        saveCollectionsToDatabase(collections);
    }

    private void importMessages(File file, byte[] key) throws Exception {
        byte[] encrypted = readBytesFromFile(file);
        byte[] decrypted = decryptData(encrypted, key);
        String json = new String(decrypted);
        List<MessageData> messages = gson.fromJson(json, List.class);
        saveMessagesToDatabase(messages);
    }

    // Helper methods...
    private <T> T readJsonFromFile(File file, Class<T> type) throws Exception {
        return gson.fromJson(new FileReader(file), type);
    }

    private byte[] decryptData(byte[] data, byte[] key) throws Exception {
        return encryption.decrypt(data, key);
    }
}
```

### EncryptionManager.java

```java
package offgrid.geogram.util;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import java.security.SecureRandom;
import java.security.spec.KeySpec;

public class EncryptionManager {

    private static final String ALGORITHM = "AES/GCM/NoPadding";
    private static final int KEY_LENGTH = 256;
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH = 16;
    private static final int PBKDF2_ITERATIONS = 10000;

    /**
     * Derive encryption key from passphrase
     */
    public byte[] deriveKey(String passphrase) throws Exception {
        byte[] salt = generateSalt();

        KeySpec spec = new PBEKeySpec(passphrase.toCharArray(), salt,
                                    PBKDF2_ITERATIONS, KEY_LENGTH);
        SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
        byte[] keyBytes = factory.generateSecret(spec).getEncoded();

        return keyBytes;
    }

    /**
     * Encrypt data with AES-256-GCM
     */
    public byte[] encrypt(byte[] data, byte[] key) throws Exception {
        byte[] iv = generateIv();
        SecretKey secretKey = new SecretKeySpec(key, "AES");

        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH * 8, iv);
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, parameterSpec);

        byte[] encrypted = cipher.doFinal(data);

        // Prepend IV to encrypted data
        byte[] result = new byte[iv.length + encrypted.length];
        System.arraycopy(iv, 0, result, 0, iv.length);
        System.arraycopy(encrypted, 0, result, iv.length, encrypted.length);

        return result;
    }

    /**
     * Decrypt data with AES-256-GCM
     */
    public byte[] decrypt(byte[] encryptedData, byte[] key) throws Exception {
        // Extract IV from beginning of data
        byte[] iv = new byte[GCM_IV_LENGTH];
        byte[] encrypted = new byte[encryptedData.length - GCM_IV_LENGTH];
        System.arraycopy(encryptedData, 0, iv, 0, iv.length);
        System.arraycopy(encryptedData, iv.length, encrypted, 0, encrypted.length);

        SecretKey secretKey = new SecretKeySpec(key, "AES");

        Cipher cipher = Cipher.getInstance(ALGORITHM);
        GCMParameterSpec parameterSpec = new GCMParameterSpec(GCM_TAG_LENGTH * 8, iv);
        cipher.init(Cipher.DECRYPT_MODE, secretKey, parameterSpec);

        return cipher.doFinal(encrypted);
    }

    private byte[] generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[16];
        random.nextBytes(salt);
        return salt;
    }

    private byte[] generateIv() {
        SecureRandom random = new SecureRandom();
        byte[] iv = new byte[GCM_IV_LENGTH];
        random.nextBytes(iv);
        return iv;
    }
}
```

---

## UI Implementation

### BackupFragment.java

```java
public class BackupFragment extends Fragment {

    private BackupManager backupManager;
    private ProgressBar progressBar;
    private TextView statusText;
    private EditText passphraseInput;
    private CheckBox settingsCheckbox;
    private CheckBox identityCheckbox;
    private CheckBox collectionsCheckbox;
    private CheckBox messagesCheckbox;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                              Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_backup, container, false);

        backupManager = new BackupManager(requireContext());

        // Initialize UI components
        progressBar = view.findViewById(R.id.backup_progress);
        statusText = view.findViewById(R.id.backup_status);
        passphraseInput = view.findViewById(R.id.passphrase_input);
        settingsCheckbox = view.findViewById(R.id.settings_checkbox);
        identityCheckbox = view.findViewById(R.id.identity_checkbox);
        collectionsCheckbox = view.findViewById(R.id.collections_checkbox);
        messagesCheckbox = view.findViewById(R.id.messages_checkbox);

        // Setup buttons
        Button exportButton = view.findViewById(R.id.export_button);
        Button importButton = view.findViewById(R.id.import_button);

        exportButton.setOnClickListener(v -> performExport());
        importButton.setOnClickListener(v -> performImport());

        return view;
    }

    private void performExport() {
        if (!validateInputs()) return;

        String passphrase = passphraseInput.getText().toString();
        List<BackupComponent> components = getSelectedComponents();

        // Request storage permission if needed
        if (!hasStoragePermission()) {
            requestStoragePermission();
            return;
        }

        // Open file picker for destination
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/zip");
        intent.putExtra(Intent.EXTRA_TITLE, generateBackupFilename());
        startActivityForResult(intent, REQUEST_EXPORT_FILE);
    }

    private void performImport() {
        if (!validateInputs()) return;

        // Open file picker for source
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("application/zip");
        startActivityForResult(intent, REQUEST_IMPORT_FILE);
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);

        if (resultCode != Activity.RESULT_OK || data == null) return;

        Uri fileUri = data.getData();
        String passphrase = passphraseInput.getText().toString();
        List<BackupComponent> components = getSelectedComponents();

        switch (requestCode) {
            case REQUEST_EXPORT_FILE:
                performExportToUri(fileUri, passphrase, components);
                break;
            case REQUEST_IMPORT_FILE:
                performImportFromUri(fileUri, passphrase, components);
                break;
        }
    }

    private void performExportToUri(Uri uri, String passphrase, List<BackupComponent> components) {
        showProgress(true);
        statusText.setText("Creating backup...");

        new Thread(() -> {
            try {
                backupManager.exportBackup(uri, passphrase, components,
                    new BackupProgressCallback() {
                        @Override
                        public void onProgress(BackupComponent component, int progress) {
                            requireActivity().runOnUiThread(() -> {
                                statusText.setText("Exporting " + component.name() + "...");
                                progressBar.setProgress(progress);
                            });
                        }

                        @Override
                        public void onComplete() {
                            requireActivity().runOnUiThread(() -> {
                                showProgress(false);
                                statusText.setText("Backup completed successfully!");
                                Toast.makeText(requireContext(),
                                    "Backup saved", Toast.LENGTH_LONG).show();
                            });
                        }

                        @Override
                        public void onError(Exception e) {
                            requireActivity().runOnUiThread(() -> {
                                showProgress(false);
                                statusText.setText("Backup failed: " + e.getMessage());
                                Toast.makeText(requireContext(),
                                    "Backup failed", Toast.LENGTH_SHORT).show();
                            });
                        }
                    });
            } catch (Exception e) {
                requireActivity().runOnUiThread(() -> {
                    showProgress(false);
                    statusText.setText("Backup failed: " + e.getMessage());
                });
            }
        }).start();
    }

    private void performImportFromUri(Uri uri, String passphrase, List<BackupComponent> components) {
        showProgress(true);
        statusText.setText("Restoring backup...");

        new Thread(() -> {
            try {
                backupManager.importBackup(uri, passphrase, components,
                    new BackupProgressCallback() {
                        @Override
                        public void onProgress(BackupComponent component, int progress) {
                            requireActivity().runOnUiThread(() -> {
                                statusText.setText("Importing " + component.name() + "...");
                                progressBar.setProgress(progress);
                            });
                        }

                        @Override
                        public void onComplete() {
                            requireActivity().runOnUiThread(() -> {
                                showProgress(false);
                                statusText.setText("Restore completed successfully!");
                                Toast.makeText(requireContext(),
                                    "Data restored", Toast.LENGTH_LONG).show();
                            });
                        }

                        @Override
                        public void onError(Exception e) {
                            requireActivity().runOnUiThread(() -> {
                                showProgress(false);
                                statusText.setText("Restore failed: " + e.getMessage());
                                Toast.makeText(requireContext(),
                                    "Restore failed", Toast.LENGTH_SHORT).show();
                            });
                        }
                    });
            } catch (Exception e) {
                requireActivity().runOnUiThread(() -> {
                    showProgress(false);
                    statusText.setText("Restore failed: " + e.getMessage());
                });
            }
        }).start();
    }

    private boolean validateInputs() {
        String passphrase = passphraseInput.getText().toString();
        if (passphrase.length() < 8) {
            Toast.makeText(requireContext(),
                "Passphrase must be at least 8 characters", Toast.LENGTH_SHORT).show();
            return false;
        }

        if (getSelectedComponents().isEmpty()) {
            Toast.makeText(requireContext(),
                "Select at least one component to backup", Toast.LENGTH_SHORT).show();
            return false;
        }

        return true;
    }

    private List<BackupComponent> getSelectedComponents() {
        List<BackupComponent> components = new ArrayList<>();

        if (settingsCheckbox.isChecked()) components.add(BackupComponent.SETTINGS);
        if (identityCheckbox.isChecked()) components.add(BackupComponent.IDENTITY);
        if (collectionsCheckbox.isChecked()) components.add(BackupComponent.COLLECTIONS);
        if (messagesCheckbox.isChecked()) components.add(BackupComponent.MESSAGES);

        return components;
    }

    private void showProgress(boolean show) {
        progressBar.setVisibility(show ? View.VISIBLE : View.GONE);
    }

    private String generateBackupFilename() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US);
        return "geogram_backup_" + sdf.format(new Date()) + ".zip";
    }

    // Permission handling methods...
    private boolean hasStoragePermission() { /* ... */ }
    private void requestStoragePermission() { /* ... */ }
}
```

---

## Data Models

### BackupComponent Enum

```java
public enum BackupComponent {
    SETTINGS("settings.json"),
    IDENTITY("identity.enc"),
    COLLECTIONS("collections.json"),
    MESSAGES("messages.enc");

    private final String filename;

    BackupComponent(String filename) {
        this.filename = filename;
    }

    public String getFilename() {
        return filename;
    }
}
```

### BackupManifest Class

```java
public class BackupManifest {
    public String version;
    public String timestamp;
    public String appVersion;
    public String deviceId;
    public Map<String, Boolean> components;
    public EncryptionInfo encryption;

    public boolean hasComponent(BackupComponent component) {
        return components.getOrDefault(component.name().toLowerCase(), false);
    }

    public static class EncryptionInfo {
        public String algorithm;
        public String keyDerivation;
        public int iterations;
    }
}
```

### Callbacks

```java
public interface BackupProgressCallback {
    void onProgress(BackupComponent component, int progress);
    void onComplete();
    void onError(Exception e);
}
```

---

## Security Considerations

### Encryption
- **AES-256-GCM**: Industry-standard encryption with authenticated encryption
- **PBKDF2**: Key derivation with 10,000 iterations for brute-force resistance
- **Secure Random**: Cryptographically secure random number generation

### Key Management
- Keys are derived from user passphrase on-demand
- No persistent key storage
- Keys exist only in memory during backup/restore operations

### Data Protection
- Sensitive data (identity, messages) is encrypted
- Non-sensitive data (settings, collections) is stored in plaintext
- Backup files contain user-controlled data only

### Privacy
- No data is transmitted to external servers
- Backups are stored locally or in user-selected locations
- Users control passphrase and backup location

---

## Testing Strategy

### Unit Tests
- Encryption/decryption correctness
- Key derivation validation
- JSON serialization/deserialization
- File I/O operations

### Integration Tests
- Full backup creation and restoration
- Large file handling (100MB+)
- Interrupted operations recovery
- Permission handling

### Security Tests
- Encryption strength validation
- Key derivation timing
- Memory cleanup verification
- File permission checks

### Manual Testing Checklist

#### Backup Creation
- [ ] Export with all components selected
- [ ] Export with subset of components
- [ ] Weak passphrase rejection
- [ ] Storage permission request
- [ ] Progress indication accuracy
- [ ] File creation in correct location

#### Backup Restoration
- [ ] Import complete backup
- [ ] Import partial backup
- [ ] Wrong passphrase rejection
- [ ] Corrupted file detection
- [ ] Data integrity verification
- [ ] Conflict resolution

#### Security Validation
- [ ] Encrypted data cannot be read without passphrase
- [ ] Backup files are properly formatted
- [ ] No sensitive data in logs
- [ ] Memory cleanup after operations

#### Edge Cases
- [ ] Large backups (>1GB)
- [ ] Low storage space handling
- [ ] Interrupted operations
- [ ] Multiple concurrent operations
- [ ] App restart during backup/restore

---

## Future Enhancements

1. **Cloud Backup**: Optional integration with user-controlled cloud storage
2. **Incremental Backup**: Only backup changed data since last backup
3. **Scheduled Backup**: Automatic backup on schedule
4. **Backup Verification**: Built-in integrity checking
5. **Cross-Platform**: Support for desktop backup tools

---

**License**: Apache-2.0
**Copyright**: 2025 Geogram Contributors