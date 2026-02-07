# Localization Guide for Florid

This document provides comprehensive information about the localization setup in Florid.

## Overview

Florid uses Flutter's built-in localization system with ARB (Application Resource Bundle) files for managing translations. We integrate with [Crowdin](https://crowdin.com/project/florid) for collaborative translation management.

## Architecture

### Localization Stack

1. **ARB Files** (`lib/l10n/app_*.arb`) - Source files containing translations
2. **Flutter's gen-l10n** - Generates type-safe Dart code from ARB files
3. **Crowdin SDK** - Provides over-the-air (OTA) translation updates
4. **Crowdin Platform** - Web-based translation management

### File Structure

```
lib/l10n/
├── app_en.arb                    # English (source language)
├── app_de.arb                    # German translations
├── app_localizations.dart         # Generated base class
├── app_localizations_en.dart      # Generated English implementation
├── app_localizations_de.dart      # Generated German implementation
└── crowdin_localizations.dart     # Crowdin SDK integration
```

## ARB File Format

ARB files are JSON-based with a specific structure:

```json
{
  "@@locale": "en",
  "key_name": "Translation text",
  "@key_name": {
    "description": "Description for translators",
    "context": "Additional context if needed"
  }
}
```

### Basic String

```json
{
  "welcome": "Welcome to Florid",
  "@welcome": {
    "description": "Welcome message shown on the home screen"
  }
}
```

### String with Placeholder

```json
{
  "no_apps_in_category": "No apps found in {category}",
  "@no_apps_in_category": {
    "description": "Message shown when no apps are found in a category. {category} is the category name.",
    "placeholders": {
      "category": {
        "type": "String",
        "example": "Games"
      }
    }
  }
}
```

### String with Multiple Placeholders

```json
{
  "delete_repository_confirm": "Are you sure you want to remove \"{name}\"?",
  "@delete_repository_confirm": {
    "description": "Confirmation message for deleting a repository. {name} is the repository name.",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "F-Droid"
      }
    }
  }
}
```

## Usage in Code

### Import the Localization Class

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### Access Translations

```dart
// Simple string
Text(AppLocalizations.of(context)!.welcome)

// String with placeholder
Text(AppLocalizations.of(context)!.no_apps_in_category('Games'))

// String with multiple placeholders
Text(AppLocalizations.of(context)!.delete_repository_confirm('F-Droid'))
```

### Using Crowdin SDK (OTA Updates)

The app uses `CrowdinLocalization` wrapper for over-the-air translation updates:

```dart
// In main.dart
MaterialApp(
  localizationsDelegates: CrowdinLocalization.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

This allows translations to be updated dynamically from Crowdin without requiring an app update.

## Adding a New Language

### 1. Create ARB File

Create a new file in `lib/l10n/` named `app_<language_code>.arb`:

```bash
# For French
touch lib/l10n/app_fr.arb

# For Spanish
touch lib/l10n/app_es.arb
```

### 2. Add Locale Metadata

Start the file with the locale identifier:

```json
{
  "@@locale": "fr"
}
```

### 3. Copy Source Translations

Copy all keys from `app_en.arb` and translate the values:

```json
{
  "@@locale": "fr",
  "app_name": "Florid",
  "welcome": "Bienvenue à Florid",
  "search": "Rechercher",
  ...
}
```

### 4. Generate Localization Files

Run Flutter's localization generator:

```bash
flutter gen-l10n
```

This will generate:
- `lib/l10n/app_localizations_fr.dart` - French implementation
- Update `app_localizations.dart` to include the new locale

### 5. Test the Translation

1. Run the app: `flutter run`
2. Change device language to the new language
3. Verify all strings appear correctly
4. Check UI layout with translated text

## Adding New Strings

### 1. Add to Base ARB File

Edit `lib/l10n/app_en.arb` and add your new string:

```json
{
  "new_feature_title": "New Feature",
  "@new_feature_title": {
    "description": "Title for the new feature screen"
  }
}
```

### 2. Regenerate Code

```bash
flutter gen-l10n
```

### 3. Use in Code

```dart
Text(AppLocalizations.of(context)!.new_feature_title)
```

### 4. Sync with Crowdin

The new string will be automatically detected by Crowdin CLI and made available for translation.

## Crowdin Integration

### Configuration

The project uses `crowdin.yml` for Crowdin CLI configuration:

```yaml
project_id: "florid"

files:
  - source: /lib/l10n/app_en.arb
    translation: /lib/l10n/app_%android_code%.arb
```

### Crowdin CLI Commands

**Upload source files to Crowdin:**
```bash
crowdin upload sources
```

**Download translations from Crowdin:**
```bash
crowdin download
```

**Check translation status:**
```bash
crowdin status
```

### Crowdin SDK (Runtime Updates)

The app uses the Crowdin SDK to fetch the latest translations at runtime. This is configured in `crowdin_localizations.dart`.

Benefits:
- Translations can be updated without releasing a new app version
- Users get the latest translations immediately
- Useful for fixing translation errors quickly

## Translation Workflow

### For Contributors

1. **Via Crowdin (Recommended):**
   - Visit [https://crowdin.com/project/florid](https://crowdin.com/project/florid)
   - Select your language
   - Start translating

2. **Via GitHub:**
   - Fork the repository
   - Edit the relevant ARB file in `lib/l10n/`
   - Run `flutter gen-l10n`
   - Test your changes
   - Submit a pull request

### For Maintainers

1. **Sync source strings to Crowdin:**
   ```bash
   crowdin upload sources
   ```

2. **Download completed translations:**
   ```bash
   crowdin download
   ```

3. **Regenerate localization files:**
   ```bash
   flutter gen-l10n
   ```

4. **Commit and release:**
   ```bash
   git add lib/l10n/
   git commit -m "Update translations from Crowdin"
   git push
   ```

## Best Practices

### For Developers

1. **Never hardcode user-facing strings** - Always use localization
2. **Provide context** - Add descriptions to help translators
3. **Use placeholders** for dynamic content
4. **Keep keys consistent** - Follow the naming convention
5. **Test with different languages** - Especially for UI layout

### For Translators

1. **Read the description** - Understand the context
2. **Be consistent** - Use the same terms throughout
3. **Keep it concise** - Mobile UIs have limited space
4. **Consider cultural context** - Adapt idioms and expressions
5. **Test if possible** - Verify translations in the actual app

### Naming Conventions

Use descriptive, hierarchical keys:

```
[screen/feature]_[component]_[element]
```

Examples:
- `home_button_search` - Search button on home screen
- `settings_section_appearance` - Appearance section in settings
- `error_network_connection` - Network connection error
- `dialog_confirm_delete` - Delete confirmation dialog

## Supported Languages

| Language | Code | Status | Contributors |
|----------|------|--------|--------------|
| English  | en   | 100%   | @Nandanrmenon |
| German   | de   | 100%   | @JasmineLowen, @mondlicht-und-sterne |

## Troubleshooting

### Translations not appearing

1. Check that `flutter gen-l10n` was run
2. Verify the ARB file has correct `@@locale` metadata
3. Ensure the device/emulator is set to the correct language
4. Check for typos in the localization key

### Missing placeholder error

Make sure placeholders in the ARB metadata match those in the string:

```json
{
  "greeting": "Hello {name}",
  "@greeting": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

### Generated files not updating

1. Clean the build: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Regenerate: `flutter gen-l10n`
4. Restart the IDE/editor

## Resources

- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [ARB File Format](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Crowdin Documentation](https://support.crowdin.com/enterprise/getting-started-for-developers/)
- [Crowdin Flutter SDK](https://github.com/crowdin/flutter-sdk)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for general contribution guidelines and translation-specific instructions.

For questions about localization, please open an issue with the `localization` label.
