# Crowdin Over-The-Air (OTA) Configuration

This file configures Crowdin's OTA content delivery for dynamic translation updates.

## Getting Your Distribution Hash

1. **Log in to Crowdin:**
   - Visit [crowdin.com/project/florid](https://crowdin.com/project/florid)
   - Or go to your Crowdin project dashboard

2. **Create or Access a Distribution:**
   - Navigate to **Settings → Distributions**
   - Click **"Create Distribution"** or select an existing one
   - Configure which languages and files to include

3. **Get the Distribution Hash:**
   - Once the distribution is created, you'll see the distribution hash
   - It's a long alphanumeric string (e.g., `a1b2c3d4e5f6g7h8`)
   - Copy this hash

4. **Configure this file:**
   - Replace `YOUR_DISTRIBUTION_HASH_HERE` with your actual hash
   - Ensure other settings match your Crowdin project configuration

## Configuration Options

```json
{
  "distributionHash": "YOUR_DISTRIBUTION_HASH_HERE",
  "sourceLanguage": "en",
  "organizationName": "florid",
  "files": [
    "/lib/l10n/app_en.arb"
  ]
}
```

### Fields:

- **distributionHash**: The distribution hash from your Crowdin project (required)
- **sourceLanguage**: The source language code (default: "en")
- **organizationName**: Your Crowdin organization or project name
- **files**: List of translation file paths in your project

## How OTA Updates Work

1. **At app startup**, the Crowdin SDK initializes with your distribution hash
2. **The SDK fetches** the distribution manifest from Crowdin's CDN
3. **Latest translations** are downloaded and cached locally
4. **Periodic checks** occur every 15 minutes for new translations
5. **Users see updates** immediately without needing to update the app

## Benefits

- ✅ Fix translation errors instantly
- ✅ Add new translations without app releases
- ✅ A/B test different translations
- ✅ Localize for new markets quickly
- ✅ Offline support with cached translations

## Testing

To test OTA updates:

1. Configure your distribution hash in this file
2. Build and run the app
3. Check the debug console for Crowdin initialization messages
4. Make a translation change in Crowdin
5. Publish the distribution
6. Wait ~15 minutes or restart the app
7. Verify the new translation appears

## Fallback

If OTA updates are not configured or fail:
- The app uses bundled ARB files as fallback
- All translations remain available offline
- No functionality is lost

## More Information

- [Crowdin Content Delivery](https://support.crowdin.com/content-delivery/)
- [Crowdin Flutter SDK](https://github.com/crowdin/flutter-sdk)
- [Project Documentation](../LOCALIZATION.md)
