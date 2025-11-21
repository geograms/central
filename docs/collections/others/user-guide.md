# Collections User Guide

This guide explains how to use Collections in Geogram from a user's perspective.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Viewing Collections](#viewing-collections)
3. [Creating a Collection](#creating-a-collection)
4. [Browsing Files](#browsing-files)
5. [Managing Files](#managing-files)
6. [Collection Settings](#collection-settings)
7. [Sharing Collections](#sharing-collections)
8. [Remote Collections](#remote-collections)
9. [Favorites](#favorites)
10. [Tips and Tricks](#tips-and-tricks)

## Getting Started

### Accessing Collections

1. Open Geogram app
2. Tap the **Collections** tab in the navigation menu
3. You'll see a list of all your collections

### Understanding Collection Types

**Owned Collections**: Collections you created (marked with "ADMIN" tag)
- You can add/remove files
- You can change settings
- You can delete the collection

**Shared Collections**: Collections received from others
- Read-only (unless permissions allow submissions)
- Can download files
- Can favorite for quick access

## Viewing Collections

### Collection List

The Collections screen shows:
- **Thumbnail**: Collection icon or custom image
- **Title**: Collection name
- **Description**: Brief description
- **File Count**: Number of files
- **Total Size**: Combined size of all files
- **ADMIN badge**: Appears if you own the collection
- **Star icon**: Appears if you favorited it

### Pull to Refresh

Swipe down on the collection list to refresh and rescan all collections.

### Search and Filter

1. Tap the search bar at the top
2. Type to filter collections by title or description
3. Results update in real-time

### Long Press Actions

Long-press any collection to see options:
- **Favorite/Unfavorite**: Toggle favorite status
- **Delete**: Remove collection (owned collections only)

## Creating a Collection

### Basic Creation

1. Tap the **+** (floating action button) in Collections screen
2. Fill in the form:
   - **Title**: Give your collection a name
   - **Description**: Describe what's in the collection
3. Choose folder type:
   - **Auto Folder**: App creates folder automatically
   - **Custom Folder**: Select existing folder from device
4. Tap **Save**

### Auto Folder Creation

The app creates a folder structure like:
```
collections/
└── {collection-id}/
    └── extra/
        ├── collection.js
        ├── security.json
        └── tree-data.js
```

You can then add files manually using the file browser.

### Custom Folder Selection

1. Uncheck "Auto Folder"
2. Tap "Select Folder"
3. Browse to the folder you want to turn into a collection
4. Tap "Select"
5. Tap "Save"

The app will:
- Scan all files in the folder
- Generate metadata
- Index all files with SHA1 hashes

### What Happens on Creation

When you create a collection:
1. **Key Pair Generated**: Unique Nostr npub/nsec keys
2. **Metadata Created**: collection.js with your title and description
3. **Security Set**: Default public, read-only permissions
4. **Files Indexed**: All files scanned and hashed
5. **Collection Saved**: Available in Collections list

**Important**: Your private key (nsec) is stored securely. Back it up if needed!

## Browsing Files

### Opening a Collection

Tap any collection to open the file browser.

### File Browser Interface

- **Header**: Shows collection info, back button, settings, info
- **Breadcrumbs**: Current folder path
- **Search**: Search files across entire collection
- **File List**: Files and folders in current directory
- **+ FAB**: Add files or folders (owned collections only)

### Navigating Folders

- **Enter Folder**: Tap any folder to open it
- **Go Back**: Tap the back button or use device back button
- **Jump to Parent**: Tap breadcrumb segments to jump up

### Opening Files

1. Tap any file
2. App opens file with default system app
   - PDFs open in PDF viewer
   - Images open in gallery
   - Documents open in document viewer
   - etc.

### File Information

Each file shows:
- **Icon**: File type icon
- **Name**: File name
- **Size**: File size (for files)
- **Description**: Optional description (if set)

## Managing Files

### Adding Files (Owned Collections Only)

1. Open your collection
2. Tap the **+** FAB
3. Choose action:
   - **Add File**: Add single file
   - **Add Folder**: Add entire folder

#### Adding a File

1. Tap "Add File"
2. Browse to the file using system file picker
3. Select file
4. File is copied to collection
5. Collection is re-scanned

#### Adding a Folder

1. Tap "Add Folder"
2. Browse to the folder
3. Select folder
4. All files are copied recursively
5. Collection is re-scanned

### Creating Folders

1. Open your collection
2. Navigate to where you want the folder
3. Tap **+** FAB → "Create Folder"
4. Enter folder name
5. Tap OK
6. Folder created and appears in list

### Renaming Files/Folders

1. Long-press file or folder
2. Tap "Rename"
3. Enter new name
4. Tap OK
5. File/folder renamed and collection rescanned

### Deleting Files/Folders

1. Long-press file or folder
2. Tap "Delete"
3. Confirm deletion
4. File/folder deleted and collection rescanned

**Warning**: Deletion is permanent!

### Rescanning Collection

If you modify files outside the app:
1. Open collection
2. Tap menu (⋮)
3. Tap "Rescan Collection"
4. File index is regenerated

This updates:
- File counts
- Total size
- SHA1 hashes
- tree-data.js

## Collection Settings

### Accessing Settings

1. Open collection
2. Tap the **Settings** icon (gear) in header
3. Settings screen appears

### Visibility Settings

Choose who can access your collection:

**Public**
- Anyone can view and download
- Good for open sharing

**Private**
- Only you can access
- Good for personal files

**Group**
- Only whitelisted users can access
- Good for controlled sharing

**Password** (Coming Soon)
- Password required to access
- Good for semi-private sharing

### User Permissions

Toggle what users can do:
- **Comment**: Allow users to comment
- **Like**: Allow users to like
- **Dislike**: Allow users to dislike
- **Rate**: Allow users to rate (1-5 stars)
- **Submit Files**: Allow users to submit files

### Group Management (Group Visibility Only)

1. Select "Group" visibility
2. Scroll to "Group Members" section
3. Tap "Add Member"
4. Enter user's Nostr npub
5. Tap "Add"
6. User can now access collection

**Removing Members**:
1. Find member in list
2. Tap delete icon
3. Member removed from whitelist

### Blocking Users

1. Scroll to "Blocked Users"
2. Tap "Add Blocked User"
3. Enter user's npub
4. User is blocked from accessing

**Note**: Blocked users override whitelist

### Content Warnings

Add warnings for potentially sensitive content:
1. Scroll to "Content Warnings"
2. Tap "Add Warning"
3. Enter warning text (e.g., "violence", "adult language")
4. Warning displayed before collection access

### Age Restrictions

Set minimum age requirement:
1. Enable "Age Restriction"
2. Set "Minimum Age" (e.g., 18)
3. Users must confirm age before access

### Saving Settings

Tap **Save** to save changes to security.json

## Sharing Collections

### Getting Collection ID

1. Open collection
2. Tap the **Info** icon (i) in header
3. Collection ID (npub) is displayed
4. Tap "Copy ID" to copy to clipboard

### Sharing the ID

Share the npub via:
- Messaging apps
- Email
- Nostr notes
- QR codes (future)

### Creating Torrent Files

For wide distribution:
1. Open collection
2. Tap menu (⋮)
3. Tap "Generate Torrent"
4. Torrent file created in `extra/` folder
5. Share .torrent file via any method

Recipients can:
- Import torrent into BitTorrent client
- Download collection over BitTorrent network

### Sharing Over P2P Network

If you're connected to other Geogram devices:
1. Collections are automatically available
2. Other devices can browse via "Remote Collections"
3. Files downloaded on-demand

No manual sharing needed!

## Remote Collections

### Browsing Remote Collections

1. Open **Remote Collections** screen
2. List shows collections from connected devices
3. Tap any collection to browse

### Remote Collection Browser

Same interface as local collections:
- Browse folders
- View file information
- Search files

### Downloading Remote Files

1. Tap any file in remote collection
2. File downloads from remote device
3. File opens when download completes
4. File cached locally

### Importing Remote Collections

To keep a remote collection:
1. Note the collection's npub
2. Ask owner to share files via torrent or direct transfer
3. Import using collection ID

## Favorites

### Favoriting a Collection

**Method 1**: Long-press in list
1. Long-press collection
2. Tap "Favorite"
3. Star appears on collection

**Method 2**: In collection browser
1. Open collection
2. Tap star icon in header
3. Collection favorited

### Viewing Favorites

Collections with star icon are your favorites.

**Future**: Filter to show only favorites

### Unfavoriting

Same as favoriting:
- Long-press → "Unfavorite"
- Or tap star icon to toggle

## Tips and Tricks

### Organizing Collections

**Use Descriptive Titles**: Make it easy to find collections later

**Group Related Files**: Create multiple collections by topic

**Use Folders**: Organize files within collections

**Tag Collections**: Add relevant tags in metadata (future)

### Performance Tips

**Large Collections**: For 1000+ files, expect longer scan times

**Thumbnails**: Add a thumbnail.jpg in collection root for custom icon (future)

**Incremental Updates**: Add files incrementally vs. rescanning everything

### Security Best Practices

**Backup Your Keys**: Export and backup collection_keys_config.json

**Set Appropriate Visibility**: Don't make private files public

**Use Group Access**: Whitelist trusted users only

**Review Permissions**: Disable submissions if you don't want user files

**Monitor Statistics**: Check who's accessing your collection (future)

### Troubleshooting

**Collection Not Appearing**:
- Pull to refresh
- Check folder structure
- Verify collection.js exists

**Files Not Showing**:
- Tap "Rescan Collection"
- Check tree-data.js exists
- Verify files exist on disk

**Can't Open File**:
- Install appropriate viewer app
- Check file isn't corrupted
- Verify permissions

**Remote Collection Not Loading**:
- Check P2P connection
- Verify remote device is online
- Check security settings allow access

**Lost Collection Ownership**:
- If you lost nsec, you can't edit collection anymore
- Restore from backup if available
- Create new collection if lost

### Advanced Usage

**Manual Metadata Editing**:
- Navigate to collection folder in file manager
- Edit collection.js, security.json with text editor
- Rescan collection in app

**Bulk File Operations**:
- Use file manager to add many files at once
- Return to app and rescan

**Collection Versioning**:
- Create timestamped copies (future feature)
- Manually duplicate collection folder

**Collection Migration**:
- Export collection folder
- Import on new device
- Import keys from collection_keys_config.json

## Getting Help

**In-App Help**: Tap (?) icon for context-sensitive help (future)

**Documentation**: Read full documentation at docs/collections/

**Community**: Ask questions on Nostr or forums

**Issues**: Report bugs on GitHub issue tracker

## Related Documentation

- [Architecture](architecture.md) - Technical details
- [Security Model](security-model.md) - Security explained
- [P2P Integration](p2p-integration.md) - Remote access details
- [FAQ](faq.md) - Frequently asked questions (future)
