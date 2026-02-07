# Quick Start: Setting Up Crowdin OTA Updates

This guide will help you set up Crowdin's Over-The-Air (OTA) translation updates for Florid.

## Step 1: Get Your Distribution Hash

1. Log in to your Crowdin project at https://crowdin.com/project/YOUR_PROJECT_NAME
   (Replace YOUR_PROJECT_NAME with your actual Crowdin project name)
2. Go to **Settings** → **Distributions**
3. Click **"Create Distribution"** or select an existing one
4. Configure your distribution:
   - **Name**: Give it a descriptive name (e.g., "Production" or "Beta")
   - **Languages**: Select which languages to include
   - **Files**: Ensure ARB files are included
   - **Export settings**: Configure as needed
5. Click **"Build"** to generate the distribution
6. Copy the **Distribution Hash** (shown after building)

## Step 2: Configure the App

Edit `assets/crowdin_config.json` and replace the placeholder:

```json
{
  "distributionHash": "a1b2c3d4e5f6g7h8i9j0",
  "sourceLanguage": "en",
  "organizationName": "florid",
  "files": [
    "/lib/l10n/app_en.arb"
  ]
}
```

**Replace `YOUR_DISTRIBUTION_HASH_HERE` with your actual hash!**

## Step 3: Test the Setup

1. **Build and run the app:**
   ```bash
   flutter run
   ```

2. **Check the console output:**
   You should see:
   ```
   Initializing Crowdin SDK with distribution hash: a1b2c3d4e5f6g7h8i9j0
   Crowdin SDK initialized successfully for OTA updates
   ```

3. **Verify translations are loading:**
   - The app should display translations normally
   - Changes made in Crowdin will appear after ~15 minutes or app restart

## Step 4: Publishing Updates

To publish new translations:

1. **Make changes in Crowdin:**
   - Edit translations via the Crowdin web interface
   - Or sync from the repository

2. **Rebuild the distribution:**
   - Go to Settings → Distributions
   - Click **"Build"** on your distribution
   - Wait for the build to complete

3. **Users receive updates:**
   - The app checks for updates every 15 minutes
   - Users can also restart the app to fetch immediately
   - No app update or Play Store release required!

## Troubleshooting

### "Distribution hash not configured" message

- Check that you replaced `YOUR_DISTRIBUTION_HASH_HERE` in `crowdin_config.json`
- Ensure the file is saved properly
- Rebuild the app after making changes

### No translations appearing

- Verify the distribution is built and published in Crowdin
- Check your internet connection
- The app falls back to bundled ARB files if OTA fails

### Debug mode

To see detailed Crowdin SDK logs, run:
```bash
flutter run --debug
```

Look for messages starting with "Crowdin" in the console.

## Benefits of OTA Updates

✅ **Instant fixes**: Correct translation errors without releasing a new app version  
✅ **Faster localization**: Add new languages immediately  
✅ **A/B testing**: Test different translations with different user groups  
✅ **Offline support**: Translations are cached locally after first download  
✅ **Zero downtime**: Falls back to bundled translations if network unavailable  

## Additional Resources

- [Full Localization Documentation](../LOCALIZATION.md)
- [Crowdin README](./CROWDIN_README.md)
- [Crowdin Content Delivery Docs](https://support.crowdin.com/content-delivery/)
- [Crowdin Flutter SDK](https://github.com/crowdin/flutter-sdk)

## Need Help?

If you encounter issues:
1. Check the [LOCALIZATION.md troubleshooting section](../LOCALIZATION.md#troubleshooting)
2. Review Crowdin SDK logs in debug mode
3. Open an issue on GitHub with the `localization` label
