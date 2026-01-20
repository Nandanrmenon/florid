# Database Migration Guide

## Overview

This application has been updated to use a SQLite database for storing F-Droid repository data instead of parsing the large JSON file on every load. This significantly improves performance and reduces loading times.

## How It Works

### Database-First Approach

1. **First Load**: The app fetches the JSON from F-Droid's repository, parses it, and imports the data into a local SQLite database.

2. **Subsequent Loads**: The app reads data directly from the database, which is much faster than parsing 40MB+ of JSON.

3. **Cache Refresh**: The database cache is considered fresh for 6 hours. After that, the app will fetch new data from the network and update the database.

### Database Schema

The database includes the following tables:
- `apps`: Main app information (name, description, icons, etc.)
- `versions`: All versions of each app with APK details
- `categories`: List of all categories
- `app_categories`: Many-to-many relationship between apps and categories
- `metadata`: Repository metadata and sync timestamps

### Performance Benefits

- **Faster Loading**: Database queries are much faster than parsing large JSON files
- **Reduced Memory**: Only load the data you need from the database
- **Better Offline Support**: Persistent database cache works even when offline
- **Efficient Searching**: Database indices enable fast search queries

## Language Support

### Default Locale

The default locale is `en-US`, matching F-Droid's default. When data is imported from JSON to the database, localized strings are extracted using the `extractLocalized` function, which prefers English variants.

### Changing Language

Users can change their preferred language in Settings > Language. The available languages include:
- English (US)
- English
- Deutsch (German)
- Español (Spanish)
- Français (French)
- Italiano (Italian)
- 日本語 (Japanese)
- 한국어 (Korean)
- Português (Brasil)
- Русский (Russian)
- 简体中文 (Simplified Chinese)

**Note**: Language changes will take effect on the next repository refresh (when the cache expires or is manually cleared).

## Migration from JSON

The migration is automatic and transparent:
- Existing JSON cache files are retained for screenshot data
- The first network fetch after updating will populate the database
- No user action is required

## Clearing Cache

Users can clear the repository cache in Settings > Storage & cache > Clear repository cache. This will:
- Delete the database
- Delete the JSON cache file
- Force a fresh fetch on next load

## Technical Details

### Files Modified
- `lib/services/database_service.dart`: New database service
- `lib/services/fdroid_api_service.dart`: Updated to use database
- `lib/providers/settings_provider.dart`: Added locale setting
- `lib/screens/settings_screen.dart`: Added language selection UI
- `lib/main.dart`: Updated provider setup
- `pubspec.yaml`: Added sqflite and path dependencies

### Backward Compatibility

The changes are designed to be backward compatible:
- JSON cache is still maintained for screenshot extraction
- If database operations fail, the app falls back to JSON parsing
- All existing API methods continue to work as before
