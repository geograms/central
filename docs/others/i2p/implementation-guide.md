# I2P Implementation Guide

## Overview

This document provides step-by-step implementation guidance for integrating I2P into Geogram Android. It covers code changes, API modifications, and UI enhancements.

## Part 1: I2P Address Generation and Storage

### 1.1 Generate I2P Destination on Demand

When the HTTP API receives a profile request, it should automatically generate an I2P destination if one doesn't exist yet.

**File**: `app/src/main/java/offgrid/geogram/server/SimpleSparkServer.java`

**Location**: `/api/profile` endpoint (around line 1450)

**Changes**:

```java
get("/api/profile", (req, res) -> {
    res.type("application/json");

    try {
        // Existing profile fields
        String npub = UserProfileManager.getInstance(context).getNpub();
        String nickname = UserProfileManager.getInstance(context).getNickname();
        String callsign = UserProfileManager.getInstance(context).getCallsign();
        String description = UserProfileManager.getInstance(context).getDescription();
        String preferredColor = UserProfileManager.getInstance(context).getPreferredColor();

        // NEW: Get or generate I2P destination
        String i2pDestination = getOrGenerateI2PDestination();
        boolean i2pEnabled = I2PService.getInstance(context).isEnabled();
        boolean i2pReady = I2PService.getInstance(context).isI2PReady();

        // Build JSON response
        JsonObject profile = new JsonObject();
        profile.addProperty("npub", npub);
        profile.addProperty("nickname", nickname);
        profile.addProperty("callsign", callsign);
        profile.addProperty("description", description);
        profile.addProperty("preferredColor", preferredColor);
        profile.addProperty("profilePicture", "/api/profile-picture");

        // Add I2P information
        JsonObject i2pInfo = new JsonObject();
        i2pInfo.addProperty("destination", i2pDestination);
        i2pInfo.addProperty("enabled", i2pEnabled);
        i2pInfo.addProperty("ready", i2pReady);
        i2pInfo.addProperty("lastSeen", System.currentTimeMillis());
        profile.add("i2p", i2pInfo);

        return profile.toString();
    } catch (Exception e) {
        Log.e("API", "Error getting profile", e);
        return createErrorResponse("Failed to get profile");
    }
});

/**
 * Get existing I2P destination or generate a new one
 */
private String getOrGenerateI2PDestination() {
    I2PService i2pService = I2PService.getInstance(context);

    // Try to get existing destination
    String destination = i2pService.getI2PDestination();

    if (destination == null || destination.isEmpty()) {
        // Generate new destination if none exists
        Log.i("I2P", "No I2P destination found, generating new one");
        destination = i2pService.generateAndSaveDestination();
    }

    return destination;
}
```

### 1.2 I2P Destination Storage

**File**: `app/src/main/java/offgrid/geogram/i2p/I2PDestination.java` (NEW FILE)

```java
package offgrid.geogram.i2p;

import android.content.Context;
import android.util.Log;
import net.i2p.I2PAppContext;
import net.i2p.client.I2PSession;
import net.i2p.data.Destination;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

/**
 * Manages I2P destination (cryptographic identity) for this device.
 *
 * Destination consists of:
 * - Public key (256 bytes)
 * - Signing key (128 bytes)
 * - Certificate (variable length)
 *
 * Base32 address: 52 characters ending in .b32.i2p
 * Full destination: 516+ character Base64 string
 */
public class I2PDestination {
    private static final String TAG = "I2PDestination";
    private static final String DEST_FILE = "destination.dat";
    private static final String DEST_DIR = "i2p";

    private Context context;
    private Destination destination;
    private String base32Address;
    private String fullDestination;

    public I2PDestination(Context context) {
        this.context = context.getApplicationContext();
        loadOrGenerateDestination();
    }

    /**
     * Load existing destination from storage or generate new one
     */
    private void loadOrGenerateDestination() {
        File destFile = getDestinationFile();

        if (destFile.exists()) {
            Log.i(TAG, "Loading existing I2P destination");
            loadDestination(destFile);
        } else {
            Log.i(TAG, "Generating new I2P destination");
            generateDestination();
            saveDestination(destFile);
        }

        // Compute derived values
        if (destination != null) {
            this.base32Address = destination.toBase32();
            this.fullDestination = destination.toBase64();
            Log.i(TAG, "I2P address: " + base32Address);
        }
    }

    /**
     * Generate new I2P destination
     */
    private void generateDestination() {
        try {
            I2PAppContext i2pContext = I2PAppContext.getGlobalContext();

            // Generate new destination with default signing key type (EdDSA)
            this.destination = i2pContext.keyGenerator().generateDestination();

            Log.i(TAG, "Generated new I2P destination");
        } catch (Exception e) {
            Log.e(TAG, "Failed to generate I2P destination", e);
        }
    }

    /**
     * Load destination from file
     */
    private void loadDestination(File file) {
        try (FileInputStream fis = new FileInputStream(file)) {
            byte[] data = new byte[(int) file.length()];
            fis.read(data);

            I2PAppContext i2pContext = I2PAppContext.getGlobalContext();
            this.destination = new Destination();
            this.destination.fromByteArray(data);

            Log.i(TAG, "Loaded I2P destination from storage");
        } catch (Exception e) {
            Log.e(TAG, "Failed to load I2P destination", e);
            generateDestination(); // Fallback to new generation
        }
    }

    /**
     * Save destination to file
     */
    private void saveDestination(File file) {
        try {
            file.getParentFile().mkdirs();

            try (FileOutputStream fos = new FileOutputStream(file)) {
                byte[] data = destination.toByteArray();
                fos.write(data);
            }

            Log.i(TAG, "Saved I2P destination to storage");
        } catch (IOException e) {
            Log.e(TAG, "Failed to save I2P destination", e);
        }
    }

    /**
     * Get destination file path
     */
    private File getDestinationFile() {
        File i2pDir = new File(context.getFilesDir(), DEST_DIR);
        return new File(i2pDir, DEST_FILE);
    }

    /**
     * Get Base32 address (e.g., ukeu3k5o...dnkdq.b32.i2p)
     */
    public String getBase32Address() {
        return base32Address;
    }

    /**
     * Get full Base64 destination string
     */
    public String getFullDestination() {
        return fullDestination;
    }

    /**
     * Get Destination object
     */
    public Destination getDestination() {
        return destination;
    }
}
```

## Part 2: Device Model Extensions

### 2.1 Add I2P Fields to Device Class

**File**: `app/src/main/java/offgrid/geogram/devices/Device.java`

**Add these fields**:

```java
public class Device {
    // Existing fields...
    private String profileNpub;
    private String wifiIp;

    // NEW: I2P support
    private String i2pDestination;           // Base32 .b32.i2p address
    private boolean i2pEnabled;              // Whether remote device has I2P enabled
    private boolean i2pReady;                // Whether remote device I2P is ready
    private long i2pLastSeen;                // Timestamp of last I2P info update
    private ConnectionMethod lastConnection; // Last successful connection method

    // Getters and setters
    public String getI2PDestination() {
        return i2pDestination;
    }

    public void setI2PDestination(String destination) {
        this.i2pDestination = destination;
        this.i2pLastSeen = System.currentTimeMillis();
    }

    public boolean isI2PEnabled() {
        return i2pEnabled;
    }

    public void setI2PEnabled(boolean enabled) {
        this.i2pEnabled = enabled;
    }

    public boolean isI2PReady() {
        return i2pReady;
    }

    public void setI2PReady(boolean ready) {
        this.i2pReady = ready;
    }

    public boolean hasI2PDestination() {
        return i2pDestination != null && !i2pDestination.isEmpty();
    }

    public long getI2PLastSeen() {
        return i2pLastSeen;
    }

    public ConnectionMethod getLastConnection() {
        return lastConnection;
    }

    public void setLastConnection(ConnectionMethod method) {
        this.lastConnection = method;
    }

    /**
     * Check if device is currently reachable via any method
     */
    public boolean isReachable() {
        return hasWiFiConnection() || (isI2PEnabled() && isI2PReady()) || isInBLERange();
    }

    /**
     * Check if device has WiFi connection
     */
    public boolean hasWiFiConnection() {
        return wifiIp != null && !wifiIp.isEmpty();
    }

    /**
     * Enum for connection methods
     */
    public enum ConnectionMethod {
        WIFI,
        I2P,
        BLE,
        NONE
    }
}
```

### 2.2 Update RemoteProfileCache for I2P

**File**: `app/src/main/java/offgrid/geogram/core/RemoteProfileCache.java`

**Add I2P caching**:

```java
public class RemoteProfileCache {

    // Existing methods...

    /**
     * Save profile with I2P information
     */
    public static void saveProfile(Context context, String deviceId,
                                   String nickname, String description,
                                   Bitmap profilePicture, String preferredColor,
                                   String npub, String i2pDestination,
                                   boolean i2pEnabled, boolean i2pReady) {
        SharedPreferences prefs = context.getSharedPreferences("remote_profiles", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        String prefix = "profile_" + deviceId + "_";

        // Existing fields
        editor.putString(prefix + "nickname", nickname);
        editor.putString(prefix + "description", description);
        editor.putString(prefix + "preferred_color", preferredColor);
        editor.putString(prefix + "npub", npub);
        editor.putLong(prefix + "timestamp", System.currentTimeMillis());

        // NEW: I2P fields
        editor.putString(prefix + "i2p_destination", i2pDestination);
        editor.putBoolean(prefix + "i2p_enabled", i2pEnabled);
        editor.putBoolean(prefix + "i2p_ready", i2pReady);
        editor.putLong(prefix + "i2p_last_seen", System.currentTimeMillis());

        // Save profile picture as Base64
        if (profilePicture != null) {
            String base64Picture = bitmapToBase64(profilePicture);
            editor.putString(prefix + "profile_picture", base64Picture);
        }

        editor.apply();
    }

    /**
     * Get cached I2P destination
     */
    public static String getI2PDestination(Context context, String deviceId) {
        SharedPreferences prefs = context.getSharedPreferences("remote_profiles", Context.MODE_PRIVATE);
        return prefs.getString("profile_" + deviceId + "_i2p_destination", null);
    }

    /**
     * Get cached I2P enabled status
     */
    public static boolean isI2PEnabled(Context context, String deviceId) {
        SharedPreferences prefs = context.getSharedPreferences("remote_profiles", Context.MODE_PRIVATE);
        return prefs.getBoolean("profile_" + deviceId + "_i2p_enabled", false);
    }

    /**
     * Get cached I2P ready status
     */
    public static boolean isI2PReady(Context context, String deviceId) {
        SharedPreferences prefs = context.getSharedPreferences("remote_profiles", Context.MODE_PRIVATE);
        return prefs.getBoolean("profile_" + deviceId + "_i2p_ready", false);
    }
}
```

## Part 3: Profile Fetching with I2P Info

### 3.1 Update Profile Fetch Logic

**File**: `app/src/main/java/offgrid/geogram/fragments/DevicesWithinReachFragment.java`

**Update `fetchProfileFromWiFi()` method**:

```java
private void fetchProfileFromWiFi(Device device) {
    String deviceId = device.ID;
    String deviceIp = wifiService.getDeviceIp(deviceId);

    if (deviceIp == null) {
        Log.w("DeviceProfile", "No WiFi IP for device " + deviceId);
        return;
    }

    // Fetch in background thread
    new Thread(() -> {
        try {
            String apiUrl = "http://" + deviceIp + ":45678/api/profile";
            String jsonResponse = httpGet(apiUrl);

            if (jsonResponse != null) {
                JsonObject profile = JsonParser.parseString(jsonResponse).getAsJsonObject();

                // Extract profile fields
                String nickname = profile.get("nickname").getAsString();
                String description = profile.has("description") ?
                    profile.get("description").getAsString() : "";
                String npub = profile.has("npub") ?
                    profile.get("npub").getAsString() : "";
                String preferredColor = profile.has("preferredColor") ?
                    profile.get("preferredColor").getAsString() : "#888888";

                // NEW: Extract I2P information
                String i2pDestination = null;
                boolean i2pEnabled = false;
                boolean i2pReady = false;

                if (profile.has("i2p")) {
                    JsonObject i2pInfo = profile.getAsJsonObject("i2p");
                    i2pDestination = i2pInfo.has("destination") ?
                        i2pInfo.get("destination").getAsString() : null;
                    i2pEnabled = i2pInfo.has("enabled") ?
                        i2pInfo.get("enabled").getAsBoolean() : false;
                    i2pReady = i2pInfo.has("ready") ?
                        i2pInfo.get("ready").getAsBoolean() : false;
                }

                // Fetch profile picture
                Bitmap profilePicture = null;
                try {
                    String pictureUrl = "http://" + deviceIp + ":45678/api/profile-picture";
                    profilePicture = downloadBitmap(pictureUrl);
                } catch (Exception e) {
                    Log.w("DeviceProfile", "Failed to fetch profile picture", e);
                }

                // Update device object
                device.setProfileNickname(nickname);
                device.setProfileDescription(description);
                device.setProfileNpub(npub);
                device.setPreferredColor(preferredColor);
                device.setI2PDestination(i2pDestination);
                device.setI2PEnabled(i2pEnabled);
                device.setI2PReady(i2pReady);
                device.setProfileFetched(true);

                // Save to cache
                RemoteProfileCache.saveProfile(
                    getContext(), deviceId, nickname, description,
                    profilePicture, preferredColor, npub,
                    i2pDestination, i2pEnabled, i2pReady
                );

                // Update UI on main thread
                getActivity().runOnUiThread(() -> {
                    adapter.notifyDataSetChanged();
                });

                Log.i("DeviceProfile", "Fetched profile for " + deviceId +
                      " (I2P: " + (i2pEnabled ? "enabled" : "disabled") + ")");
            }
        } catch (Exception e) {
            Log.e("DeviceProfile", "Error fetching profile", e);
        }
    }).start();
}
```

### 3.2 Load I2P Info from Cache

**Update `loadNearbyDevices()` in same file**:

```java
private void loadNearbyDevices() {
    TreeSet<Device> devices = DeviceManager.getInstance().getDevicesSpotted();

    for (Device device : devices) {
        String deviceId = device.ID;

        // Load from cache for immediate display
        if (RemoteProfileCache.isCacheValid(getContext(), deviceId)) {
            String cachedNickname = RemoteProfileCache.getNickname(getContext(), deviceId);
            String cachedDescription = RemoteProfileCache.getDescription(getContext(), deviceId);
            String cachedNpub = RemoteProfileCache.getNpub(getContext(), deviceId);
            String cachedColor = RemoteProfileCache.getPreferredColor(getContext(), deviceId);

            // NEW: Load I2P info from cache
            String cachedI2PDest = RemoteProfileCache.getI2PDestination(getContext(), deviceId);
            boolean cachedI2PEnabled = RemoteProfileCache.isI2PEnabled(getContext(), deviceId);
            boolean cachedI2PReady = RemoteProfileCache.isI2PReady(getContext(), deviceId);

            if (cachedNickname != null) {
                device.setProfileNickname(cachedNickname);
            }
            if (cachedDescription != null) {
                device.setProfileDescription(cachedDescription);
            }
            if (cachedNpub != null) {
                device.setProfileNpub(cachedNpub);
            }
            if (cachedColor != null) {
                device.setPreferredColor(cachedColor);
            }
            if (cachedI2PDest != null) {
                device.setI2PDestination(cachedI2PDest);
                device.setI2PEnabled(cachedI2PEnabled);
                device.setI2PReady(cachedI2PReady);
            }
        }

        // Always try to fetch fresh data if WiFi available
        String deviceIp = wifiService.getDeviceIp(deviceId);
        if (deviceIp != null) {
            // Anti-spam: only fetch if not fetched in last minute
            long timeSinceLastFetch = System.currentTimeMillis() - device.getLastReachabilityCheck();
            if (timeSinceLastFetch > 60000) {
                fetchProfileFromWiFi(device);
            }
        }
    }
}
```

## Part 4: UI Indicators for I2P Status

### 4.1 Add I2P Tag to Device List

**File**: `app/src/main/res/layout/item_device.xml` (device list item layout)

**Add I2P status badge**:

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:orientation="horizontal"
    android:padding="12dp"
    android:gravity="center_vertical">

    <!-- Profile Picture -->
    <ImageView
        android:id="@+id/device_profile_picture"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:src="@drawable/default_profile" />

    <!-- Device Info -->
    <LinearLayout
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_weight="1"
        android:orientation="vertical"
        android:paddingStart="12dp">

        <!-- Nickname and Connection Badges -->
        <LinearLayout
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:orientation="horizontal"
            android:gravity="center_vertical">

            <TextView
                android:id="@+id/device_nickname"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:text="Device Nickname"
                android:textColor="@color/white"
                android:textSize="16sp"
                android:textStyle="bold" />

            <!-- WiFi Badge -->
            <TextView
                android:id="@+id/badge_wifi"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="8dp"
                android:background="#4CAF50"
                android:text="WiFi"
                android:textColor="@color/white"
                android:textSize="10sp"
                android:paddingStart="6dp"
                android:paddingEnd="6dp"
                android:paddingTop="2dp"
                android:paddingBottom="2dp"
                android:visibility="gone" />

            <!-- I2P Badge -->
            <TextView
                android:id="@+id/badge_i2p"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="4dp"
                android:background="#9C27B0"
                android:text="I2P"
                android:textColor="@color/white"
                android:textSize="10sp"
                android:paddingStart="6dp"
                android:paddingEnd="6dp"
                android:paddingTop="2dp"
                android:paddingBottom="2dp"
                android:visibility="gone" />

            <!-- BLE Badge -->
            <TextView
                android:id="@+id/badge_ble"
                android:layout_width="wrap_content"
                android:layout_height="wrap_content"
                android:layout_marginStart="4dp"
                android:background="#2196F3"
                android:text="BLE"
                android:textColor="@color/white"
                android:textSize="10sp"
                android:paddingStart="6dp"
                android:paddingEnd="6dp"
                android:paddingTop="2dp"
                android:paddingBottom="2dp"
                android:visibility="gone" />
        </LinearLayout>

        <!-- Callsign -->
        <TextView
            android:id="@+id/device_callsign"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:text="CALLSIGN"
            android:textColor="#AAAAAA"
            android:textSize="12sp"
            android:paddingTop="2dp" />
    </LinearLayout>
</LinearLayout>
```

### 4.2 Update Adapter to Show I2P Tags

**File**: `app/src/main/java/offgrid/geogram/adapters/DeviceAdapter.java`

```java
public class DeviceAdapter extends RecyclerView.Adapter<DeviceAdapter.ViewHolder> {

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        Device device = devices.get(position);

        // Set nickname and callsign
        holder.nicknameView.setText(device.getProfileNickname());
        holder.callsignView.setText(device.callsign);

        // Set profile picture
        if (device.hasProfilePicture()) {
            holder.profilePicture.setImageBitmap(device.getProfilePicture());
        }

        // NEW: Show connection method badges
        showConnectionBadges(holder, device);

        holder.itemView.setOnClickListener(v -> {
            if (onDeviceClickListener != null) {
                onDeviceClickListener.onDeviceClick(device);
            }
        });
    }

    /**
     * Show badges for available connection methods
     */
    private void showConnectionBadges(ViewHolder holder, Device device) {
        // WiFi badge
        if (device.hasWiFiConnection()) {
            holder.wifiBadge.setVisibility(View.VISIBLE);
        } else {
            holder.wifiBadge.setVisibility(View.GONE);
        }

        // I2P badge
        if (device.hasI2PDestination() && device.isI2PEnabled()) {
            holder.i2pBadge.setVisibility(View.VISIBLE);

            // Change color based on ready status
            if (device.isI2PReady()) {
                holder.i2pBadge.setBackgroundColor(0xFF9C27B0); // Purple - ready
            } else {
                holder.i2pBadge.setBackgroundColor(0xFF757575); // Gray - not ready
            }
        } else {
            holder.i2pBadge.setVisibility(View.GONE);
        }

        // BLE badge
        if (device.isInBLERange()) {
            holder.bleBadge.setVisibility(View.VISIBLE);
        } else {
            holder.bleBadge.setVisibility(View.GONE);
        }
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView nicknameView;
        TextView callsignView;
        ImageView profilePicture;
        TextView wifiBadge;
        TextView i2pBadge;
        TextView bleBadge;

        ViewHolder(View itemView) {
            super(itemView);
            nicknameView = itemView.findViewById(R.id.device_nickname);
            callsignView = itemView.findViewById(R.id.device_callsign);
            profilePicture = itemView.findViewById(R.id.device_profile_picture);
            wifiBadge = itemView.findViewById(R.id.badge_wifi);
            i2pBadge = itemView.findViewById(R.id.badge_i2p);
            bleBadge = itemView.findViewById(R.id.badge_ble);
        }
    }
}
```

## Part 5: Connection Fallback Logic

### 5.1 ConnectionManager Implementation

**File**: `app/src/main/java/offgrid/geogram/network/ConnectionManager.java` (NEW FILE)

```java
package offgrid.geogram.network;

import android.content.Context;
import android.util.Log;
import offgrid.geogram.devices.Device;
import offgrid.geogram.i2p.I2PService;
import offgrid.geogram.i2p.I2PHttpClient;
import offgrid.geogram.services.WiFiDiscoveryService;

/**
 * Manages connection routing between WiFi, I2P, and BLE.
 *
 * Connection priority:
 * 1. WiFi (fastest, lowest latency)
 * 2. I2P (global reach, higher latency)
 * 3. BLE (local only, discovery only)
 */
public class ConnectionManager {
    private static final String TAG = "ConnectionManager";
    private static ConnectionManager instance;

    private Context context;
    private I2PService i2pService;
    private WiFiDiscoveryService wifiService;

    private ConnectionManager(Context context) {
        this.context = context.getApplicationContext();
        this.i2pService = I2PService.getInstance(context);
        this.wifiService = WiFiDiscoveryService.getInstance(context);
    }

    public static synchronized ConnectionManager getInstance(Context context) {
        if (instance == null) {
            instance = new ConnectionManager(context);
        }
        return instance;
    }

    /**
     * Select best connection method for device
     */
    public Device.ConnectionMethod selectConnectionMethod(Device device) {
        // Priority 1: WiFi (if available)
        if (device.hasWiFiConnection()) {
            String wifiIp = wifiService.getDeviceIp(device.ID);
            if (wifiIp != null && !wifiIp.isEmpty()) {
                Log.d(TAG, "Selected WiFi for device " + device.ID);
                return Device.ConnectionMethod.WIFI;
            }
        }

        // Priority 2: I2P (if device has I2P and our I2P is ready)
        if (device.hasI2PDestination() && device.isI2PEnabled()) {
            if (i2pService.isI2PReady()) {
                Log.d(TAG, "Selected I2P for device " + device.ID);
                return Device.ConnectionMethod.I2P;
            } else {
                Log.w(TAG, "Device " + device.ID + " has I2P but our I2P is not ready");
            }
        }

        // Priority 3: BLE (local discovery only, not for collections)
        if (device.isInBLERange()) {
            Log.d(TAG, "Selected BLE for device " + device.ID);
            return Device.ConnectionMethod.BLE;
        }

        Log.w(TAG, "No connection method available for device " + device.ID);
        return Device.ConnectionMethod.NONE;
    }

    /**
     * Fetch profile using best available connection method
     */
    public ProfileResponse fetchProfile(Device device) {
        Device.ConnectionMethod method = selectConnectionMethod(device);
        device.setLastConnection(method);

        switch (method) {
            case WIFI:
                return fetchProfileViaWiFi(device);
            case I2P:
                return fetchProfileViaI2P(device);
            case BLE:
                // BLE doesn't support profile fetching
                return new ProfileResponse(false, "BLE doesn't support profile transfer", method);
            case NONE:
                return new ProfileResponse(false, "No connection method available", method);
            default:
                return new ProfileResponse(false, "Unknown connection method", method);
        }
    }

    /**
     * Fetch profile via WiFi
     */
    private ProfileResponse fetchProfileViaWiFi(Device device) {
        try {
            String deviceIp = wifiService.getDeviceIp(device.ID);
            String apiUrl = "http://" + deviceIp + ":45678/api/profile";

            // Use standard HTTP client
            String jsonResponse = httpGet(apiUrl);

            return new ProfileResponse(true, jsonResponse, Device.ConnectionMethod.WIFI);
        } catch (Exception e) {
            Log.e(TAG, "WiFi profile fetch failed", e);
            return new ProfileResponse(false, e.getMessage(), Device.ConnectionMethod.WIFI);
        }
    }

    /**
     * Fetch profile via I2P
     */
    private ProfileResponse fetchProfileViaI2P(Device device) {
        try {
            String i2pDest = device.getI2PDestination();

            // Use I2P HTTP client
            I2PHttpClient i2pClient = new I2PHttpClient(context);
            String jsonResponse = i2pClient.get(i2pDest, "/api/profile");

            return new ProfileResponse(true, jsonResponse, Device.ConnectionMethod.I2P);
        } catch (Exception e) {
            Log.e(TAG, "I2P profile fetch failed", e);
            return new ProfileResponse(false, e.getMessage(), Device.ConnectionMethod.I2P);
        }
    }

    /**
     * Fetch collections list using best available connection
     */
    public CollectionsResponse fetchCollections(Device device) {
        Device.ConnectionMethod method = selectConnectionMethod(device);
        device.setLastConnection(method);

        switch (method) {
            case WIFI:
                return fetchCollectionsViaWiFi(device);
            case I2P:
                return fetchCollectionsViaI2P(device);
            case BLE:
            case NONE:
                return new CollectionsResponse(false, "No suitable connection method", method);
            default:
                return new CollectionsResponse(false, "Unknown connection method", method);
        }
    }

    /**
     * Fetch collections via WiFi
     */
    private CollectionsResponse fetchCollectionsViaWiFi(Device device) {
        try {
            String deviceIp = wifiService.getDeviceIp(device.ID);
            String apiUrl = "http://" + deviceIp + ":45678/api/collections";

            String jsonResponse = httpGet(apiUrl);

            return new CollectionsResponse(true, jsonResponse, Device.ConnectionMethod.WIFI);
        } catch (Exception e) {
            Log.e(TAG, "WiFi collections fetch failed", e);
            return new CollectionsResponse(false, e.getMessage(), Device.ConnectionMethod.WIFI);
        }
    }

    /**
     * Fetch collections via I2P
     */
    private CollectionsResponse fetchCollectionsViaI2P(Device device) {
        try {
            String i2pDest = device.getI2PDestination();

            I2PHttpClient i2pClient = new I2PHttpClient(context);
            String jsonResponse = i2pClient.get(i2pDest, "/api/collections");

            return new CollectionsResponse(true, jsonResponse, Device.ConnectionMethod.I2P);
        } catch (Exception e) {
            Log.e(TAG, "I2P collections fetch failed", e);
            return new CollectionsResponse(false, e.getMessage(), Device.ConnectionMethod.I2P);
        }
    }

    // Helper classes for responses
    public static class ProfileResponse {
        public boolean success;
        public String data;
        public Device.ConnectionMethod method;

        public ProfileResponse(boolean success, String data, Device.ConnectionMethod method) {
            this.success = success;
            this.data = data;
            this.method = method;
        }
    }

    public static class CollectionsResponse {
        public boolean success;
        public String data;
        public Device.ConnectionMethod method;

        public CollectionsResponse(boolean success, String data, Device.ConnectionMethod method) {
            this.success = success;
            this.data = data;
            this.method = method;
        }
    }
}
```

### 5.2 Use ConnectionManager in DeviceProfileFragment

**File**: `app/src/main/java/offgrid/geogram/fragments/DeviceProfileFragment.java`

**Update collections loading**:

```java
private void setupCollectionsCard(View rootView, String deviceId, Device device) {
    LinearLayout collectionsCard = rootView.findViewById(R.id.collections_card);
    TextView emptyCollections = rootView.findViewById(R.id.empty_collections);
    RecyclerView recyclerCollections = rootView.findViewById(R.id.recycler_collections);

    // Use ConnectionManager to fetch collections
    new Thread(() -> {
        ConnectionManager connectionManager = ConnectionManager.getInstance(getContext());
        ConnectionManager.CollectionsResponse response = connectionManager.fetchCollections(device);

        getActivity().runOnUiThread(() -> {
            if (response.success) {
                try {
                    JsonArray collections = JsonParser.parseString(response.data).getAsJsonArray();

                    if (collections.size() > 0) {
                        // Show collections
                        List<Collection> collectionList = parseCollections(collections);
                        collectionsAdapter.setCollections(collectionList);
                        recyclerCollections.setVisibility(View.VISIBLE);
                        emptyCollections.setVisibility(View.GONE);

                        // Show connection method badge
                        String methodText = response.method == Device.ConnectionMethod.WIFI ?
                            "via WiFi" : "via I2P";
                        Log.i("Collections", "Loaded " + collections.size() + " collections " + methodText);
                    } else {
                        recyclerCollections.setVisibility(View.GONE);
                        emptyCollections.setVisibility(View.VISIBLE);
                    }
                } catch (Exception e) {
                    Log.e("Collections", "Error parsing collections", e);
                    recyclerCollections.setVisibility(View.GONE);
                    emptyCollections.setVisibility(View.VISIBLE);
                }
            } else {
                Log.e("Collections", "Failed to fetch collections: " + response.data);
                recyclerCollections.setVisibility(View.GONE);
                emptyCollections.setVisibility(View.VISIBLE);
                emptyCollections.setText("Failed to load collections: " + response.data);
            }
        });
    }).start();
}
```

## Summary

This implementation guide covers:

1. **Auto-generation of I2P destinations** when profiles are requested
2. **Storage and persistence** of I2P destinations
3. **Caching I2P information** alongside other profile data
4. **UI indicators** showing I2P availability with badges
5. **Connection fallback logic** that tries WiFi first, then I2P, then BLE
6. **Seamless switching** between connection methods based on availability

The key insight is that I2P becomes a **transparent fallback mechanism**: when devices can't reach each other via WiFi, they automatically use I2P if available, with no user intervention required.
