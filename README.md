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
- **Web Companion Store** (NEW): Pair your device with a web browser to remotely trigger app installations

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

## Architecture

- State management: Provider
- Data layer: `FDroidApiService` (network + download) and `DatabaseService` (SQLite via `sqflite`) with cache‑first fallback
- Serialization: `json_serializable` + `build_runner`
- UI: Flutter Material 3 components and custom widgets
- Notifications: `flutter_local_notifications` for download progress/completion

### Repository & Caching

- Fetches `index-v2.json` from F‑Droid, parses into models, persists to SQLite
- Falls back to local DB or JSON cache when offline or on failures
- Extracts screenshots from raw metadata when available

### Project Structure

```
lib/
├── models/          # Data models (FDroidApp, FDroidVersion, InstallCommand, PairedDevice)
├── providers/       # App, download, and settings providers
├── screens/         # UI screens (Latest, Categories, Updates, Details, Pairing, ...)
├── services/        # API, database, notifications, web sync, device pairing
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
backend/             # Node.js backend server for web companion store
```

## Web Companion Store (Beta)

Florid now supports a web companion store that allows you to browse F-Droid apps on your computer and remotely trigger installations on your paired mobile device. This feature works entirely without Google Play Services.

### Features

- **Device Pairing**: Scan a QR code or enter a pairing code to link your mobile device with the web companion
- **Remote Install**: Browse apps on the web and send install commands to your paired device
- **Real-time Sync**: WebSocket-based communication for instant delivery of install requests
- **Notifications**: Receive notifications on your mobile device when remote install requests arrive
- **Queue Management**: View and manage pending remote install requests on your device

### How It Works

1. **Mobile App**: Open Settings → Web Store Sync → Pair with Web Store
2. **Display QR Code**: The app generates a QR code and pairing code
3. **Web Browser**: Visit the web companion store (requires backend server)
4. **Scan or Enter Code**: Use the QR code or enter the 6-digit pairing code
5. **Paired**: Your device is now paired and will receive remote install requests
6. **Browse & Install**: Browse apps on the web and click "Install on Device"
7. **Receive Notification**: Your mobile device receives a notification
8. **Download & Install**: Open the notification to view and start the installation

### Backend Server

The web companion store requires a backend server to facilitate communication between the web frontend and mobile devices. The server handles:

- User authentication
- Device pairing management
- WebSocket connections for real-time messaging
- Install command queuing

See [`backend/README.md`](backend/README.md) for setup and deployment instructions.

### Security

- **JWT Authentication**: Secure token-based authentication for API requests
- **Device IDs**: Unique UUIDs generated per device
- **Pairing Codes**: Time-limited 6-digit codes for secure pairing
- **WebSocket Auth**: All WebSocket connections are authenticated
- **Rate Limiting**: API endpoints are rate-limited to prevent abuse

### Deployment

The backend server can be deployed to any Node.js hosting platform:

- **Heroku**: Free tier available, easy deployment
- **Railway.app**: Modern platform with free tier
- **Render.com**: Free tier with automatic deploys
- **Your Own Server**: Any server with Node.js support

See the backend README for detailed deployment instructions.

### Future Enhancements

- Flutter Web frontend (reusing mobile app code)
- Multi-device support (install on multiple devices simultaneously)
- Install history and analytics
- Remote uninstall capability
- Batch install (multiple apps at once)
- UnifiedPush integration for better battery efficiency

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
