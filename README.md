<div align="center">

# <img src="assets/Florid.png" alt="Florid logo" width="120" height="120" style="border-radius:99px; vertical-align:middle; margin-right:12px;" /> Florid — A Modern F‑Droid Client for Android

Browse, search, and install open‑source Android apps from the F‑Droid repository with a clean Material 3 UI. Built with Flutter.

</div>

<div align="center">
	<a href="https://github.com/Nandanrmenon/florid/releases/latest">
		<img src="https://img.shields.io/github/v/release/Nandanrmenon/florid?label=Latest%20release&logo=github&style=for-the-badge" alt="Latest release" />
	</a>
	<a href="https://apt.izzysoft.de/packages/com.nahnah.florid">
		<img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroidButtonGreyBorder_nofont.png" alt="Get it at IzzyOnDroid" height="50"/>
	</a>
</div>

## Features

- Latest and trending: Browse recently added and updated apps
- Categories: Explore apps organized by topic
- Powerful search: Instant filtering by name, summary, description, or package
- App details: Rich metadata, versions, permissions, links, and changelogs
- Screenshots: Inline screenshots when available from the repo metadata
- Downloads: Reliable APK downloads with progress and notifications
- Install/uninstall: One‑tap install of downloaded APKs, uninstall via intent
- Updates: Detect newer versions for apps installed on your device
- Appearance: Material 3 design with light/dark and system themes
- Localization: Choose repository content language (e.g., en‑US, de‑DE)
- Offline cache: Fast local database with smart network/cache fallback
- **Web Store**: Browse F-Droid apps on the web and trigger installs on your paired mobile device
- **Remote Install**: Pair your mobile device with the web version to install apps remotely

## Screenshots

|                                                               |                                                                |                                                               |                                                               |
| :-----------------------------------------------------------: | :------------------------------------------------------------: | :-----------------------------------------------------------: | :-----------------------------------------------------------: |
| <img src="assets/screenshots/Screenshot-1.png" width="260" /> | <img src="assets/screenshots/Screenshot-2.png" width="260" />  | <img src="assets/screenshots/Screenshot-3.png" width="260" /> | <img src="assets/screenshots/Screenshot-4.png" width="260" /> |
| <img src="assets/screenshots/Screenshot-5.png" width="260" /> | <img src="assets/screenshots/Screenshot-6.png" width="260" />  | <img src="assets/screenshots/Screenshot-7.png" width="260" /> | <img src="assets/screenshots/Screenshot-8.png" width="260" /> |
| <img src="assets/screenshots/Screenshot-9.png" width="260" /> | <img src="assets/screenshots/Screenshot-10.png" width="260" /> |                                                               |                                                               |

## Getting Started

### Prerequisites

- Flutter (stable channel)
- Dart SDK >= 3.9.2
- Android SDK + device/emulator (Android 8.0+ recommended)

### Setup

1. Install dependencies

```bash
flutter pub get
```

2. Run on a device

```bash
flutter run
```

First launch performs an initial repository sync and caches data locally for faster subsequent loads and limited offline use.

### Build

Build a release APK:

```bash
flutter build apk
```

Build for web:

```bash
flutter build web
```

## Web Store & Remote Install

Florid now supports a web version that allows you to browse apps and trigger installations on your paired mobile device.

### How it works

1. **On Mobile**: 
   - Open Florid app
   - Go to Settings → Pair with Web
   - Note the 6-digit pairing code displayed

2. **On Web**: 
   - Open the Florid web app in your browser
   - Click "Enter Pairing Code"
   - Enter the 6-digit code from your mobile device
   - Once paired, browse apps and click "Install" to send the app to your mobile

3. **Installation**:
   - Your mobile device receives a notification
   - Tap the notification to see download/install progress
   - The app downloads and can be installed directly

This feature works without any Google services or proprietary protocols - it uses a simple pairing mechanism built entirely in Flutter.

## Architecture

- State management: Provider
- Data layer: `FDroidApiService` (network + download) and `DatabaseService` (SQLite via `sqflite`) with cache‑first fallback
- Serialization: `json_serializable` + `build_runner`
- UI: Flutter Material 3 components and custom widgets
- Notifications: `flutter_local_notifications` for download progress/completion
- Pairing: `PairingService` for web-mobile communication using in-memory message queue (can be replaced with a server implementation)

### Repository & Caching

- Fetches `index-v2.json` from F‑Droid, parses into models, persists to SQLite
- Falls back to local DB or JSON cache when offline or on failures
- Extracts screenshots from raw metadata when available

### Web-Mobile Communication

- Uses a pairing code system (6-digit code) for secure device pairing
- Message queue for install requests and status updates
- Currently uses in-memory queue (suitable for local testing)
- Can be easily extended to use a server backend for production use

### Project Structure

```
lib/
├── models/          # Data models (FDroidApp, FDroidVersion, ...)
├── providers/       # App, download, pairing, and settings providers
├── screens/         # UI screens (Latest, Categories, Updates, Details, Pairing, RemoteInstall, WebStore, ...)
├── services/        # API, database, notifications, pairing utilities
├── widgets/         # Reusable UI components
└── main.dart        # App entry point with platform detection
web/                 # Web platform files
├── index.html       # Web entry point
├── manifest.json    # PWA manifest
└── icons/           # PWA icons
```

## Permissions

Florid uses the following Android permissions for core functionality:

- INTERNET: Access the F‑Droid repository and app metadata
- REQUEST_INSTALL_PACKAGES: Install downloaded APKs
- POST_NOTIFICATIONS (Android 13+): Show download notifications
- QUERY_ALL_PACKAGES: Detect installed apps to surface available updates
- Storage access: APK files are stored in the app’s external Downloads dir; on Android 13+ this typically works without the legacy storage permission

Actual permissions are declared in the Android manifest and requested at runtime where required.

## Development

- Regenerate splash screen (configured in `splash_screen.yaml`):

```bash
flutter pub run flutter_native_splash:create
```

- Regenerate app icons (configured in `icon_launcher.yaml`):

```bash
flutter pub run icons_launcher:create
```

## Dependencies (selected)

- provider, http, dio, cached_network_image, flutter_cache_manager
- sqflite, path_provider, shared_preferences
- permission_handler, package_info_plus, installed_apps, android_intent_plus
- flutter_local_notifications, url_launcher, share_plus
- json_annotation, json_serializable, build_runner

## Contributing

Issues and PRs are welcome! Please:

- Open an issue for bugs or feature requests
- Keep PRs focused and include concise descriptions
- Follow the existing code style and Provider architecture

## License

GPL‑3.0 — see LICENSE for full text.

## Disclaimer

Florid is an independent project and is not affiliated with or endorsed by F‑Droid. “F‑Droid” is a trademark of its respective owners.
