# Flutter Web Frontend - Complete Guide

## Overview

The Flutter Web frontend provides a web-based interface for browsing F-Droid apps and remotely installing them on paired mobile devices. It's built with Flutter Web to maximize code reuse with the mobile app.

## Features

### 1. User Authentication
- **Login**: Authenticate with backend server
- **Registration**: Create new user accounts
- **Session Management**: JWT-based authentication with persistent storage

### 2. Device Management
- **Pair Devices**: Pair mobile devices using 6-digit pairing code
- **Device Selection**: Select target device from dropdown
- **Device Status**: View online/offline status
- **Multiple Devices**: Manage multiple paired devices

### 3. App Browsing
- **Browse Apps**: View latest F-Droid apps
- **Search**: Real-time search functionality
- **App Details**: View detailed app information
- **Responsive Grid**: Adaptive layout for different screen sizes

### 4. Remote Installation
- **Install Button**: One-click install to selected device
- **Install Feedback**: Visual confirmation of install requests
- **Queue Support**: Backend queues commands for offline devices

## Architecture

### Services

#### WebAuthService
```dart
// lib/services/web_auth_service.dart
- User registration and login
- JWT token management
- Session persistence with SharedPreferences
- Logout functionality
```

#### WebDeviceService
```dart
// lib/services/web_device_service.dart
- Fetch paired devices from backend
- Pair new devices
- Unpair devices
- Send install commands
- Device selection management
```

### Screens

#### WebLoginScreen
- User authentication UI
- Toggle between login/registration
- Form validation
- Loading states

#### WebHomeScreen
- App browsing with grid layout
- Search functionality
- Device selector in app bar
- Refresh and logout actions

#### WebAppDetailsScreen
- Detailed app information
- "Install on Device" button
- App icon, description, metadata
- Install feedback

#### WebPairingScreen
- Device pairing form
- 6-digit pairing code input
- Device ID and name fields
- Pairing confirmation

#### WebDeviceSelector
- Device dropdown menu
- Show active/offline status
- Quick device switching
- "Pair New Device" option

### Data Flow

```
User Login
    ↓
WebAuthService → Backend API
    ↓
JWT Token Stored
    ↓
Fetch Devices → WebDeviceService → Backend API
    ↓
Browse Apps → AppProvider → FDroidApiService
    ↓
Select App → WebAppDetailsScreen
    ↓
Click "Install on Device"
    ↓
WebDeviceService → Backend API → Mobile Device
```

## Setup and Configuration

### 1. Backend URL Configuration

Update the backend URL in both service files:

**lib/services/web_auth_service.dart:**
```dart
static const String _baseUrl =
    kDebugMode ? 'http://localhost:3000' : 'https://your-backend.com';
```

**lib/services/web_device_service.dart:**
```dart
static const String _baseUrl =
    kDebugMode ? 'http://localhost:3000' : 'https://your-backend.com';
```

Replace `'https://your-backend.com'` with your deployed backend URL.

### 2. Running Locally

```bash
# Run in Chrome
flutter run -d chrome --web-renderer html --target lib/main_web.dart

# Run in Edge
flutter run -d edge --web-renderer html --target lib/main_web.dart
```

The `--web-renderer html` flag is recommended for better compatibility.

### 3. Building for Production

```bash
flutter build web --release --web-renderer html --target lib/main_web.dart
```

Built files will be in `build/web/` directory.

### 4. Deployment

The web app is a static site and can be deployed to any hosting service:

#### GitHub Pages
```bash
# Build for production
flutter build web --release --web-renderer html --target lib/main_web.dart

# Deploy to gh-pages branch
cd build/web
git init
git add .
git commit -m "Deploy web app"
git push -f git@github.com:username/florid.git main:gh-pages
```

#### Netlify
1. Connect your GitHub repository
2. Set build command: `flutter build web --release --web-renderer html --target lib/main_web.dart`
3. Set publish directory: `build/web`
4. Deploy

#### Vercel
1. Connect your GitHub repository
2. Set build command: `flutter build web --release --web-renderer html --target lib/main_web.dart`
3. Set output directory: `build/web`
4. Deploy

#### Firebase Hosting
```bash
# Build for production
flutter build web --release --web-renderer html --target lib/main_web.dart

# Deploy to Firebase
firebase init hosting
firebase deploy
```

## Usage Guide

### For Users

1. **First Time Setup**
   - Open the web app in your browser
   - Click "Register" if you don't have an account
   - Enter username and password
   - Click "Register"

2. **Pair Your Mobile Device**
   - Open Florid app on your Android device
   - Go to Settings → Web Store Sync → Pair with Web Store
   - Note the 6-digit pairing code, Device ID, and Device Name
   - In the web app, click "Pair Device" in the top-right
   - Enter the pairing code, Device ID, and Device Name
   - Click "Pair Device"

3. **Browse and Install Apps**
   - Search for apps using the search bar
   - Click on an app to view details
   - Ensure your device is selected in the dropdown
   - Click "Install on [Device Name]"
   - Your mobile device will receive a notification

4. **Manage Devices**
   - Click the device dropdown in the top-right
   - See all paired devices with online/offline status
   - Switch between devices
   - Active devices shown with green icon

### For Developers

#### Adding New Features

1. **Add New Screen**
   ```dart
   // lib/screens/web/new_screen.dart
   import 'package:flutter/material.dart';
   
   class NewScreen extends StatelessWidget {
     const NewScreen({super.key});
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('New Screen')),
         body: const Center(child: Text('New Feature')),
       );
     }
   }
   ```

2. **Add New Service Method**
   ```dart
   // lib/services/web_device_service.dart
   Future<bool> newFeature() async {
     try {
       final response = await http.post(
         Uri.parse('$_baseUrl/api/new-endpoint'),
         headers: _authService.getAuthHeaders(),
       );
       return response.statusCode == 200;
     } catch (e) {
       debugPrint('Error: $e');
       return false;
     }
   }
   ```

3. **Update Provider**
   ```dart
   // lib/main_web.dart
   ChangeNotifierProvider<NewService>(
     create: (_) => NewService(),
   ),
   ```

## Troubleshooting

### CORS Issues

If you encounter CORS errors, ensure your backend server allows requests from your web app domain:

```javascript
// backend/server.js
const cors = require('cors');
app.use(cors({
  origin: ['http://localhost:3000', 'https://your-web-app.com'],
  credentials: true
}));
```

### Authentication Issues

- Check that backend URL is correct in service files
- Verify JWT_SECRET is set in backend environment
- Clear browser localStorage and try again
- Check browser console for detailed error messages

### Device Pairing Issues

- Ensure mobile device has internet connection
- Verify pairing code hasn't expired (5 minutes)
- Check that Device ID and Device Name are correct
- Ensure backend server is running and accessible

### Install Command Not Received

- Check device is online (green icon in device selector)
- Verify WebSocket connection on mobile device
- Check backend logs for errors
- Try refreshing device list

## Performance Optimization

### 1. Lazy Loading
```dart
// Load apps on demand
Future<void> _loadMoreApps() async {
  await appProvider.fetchLatestApps(
    limit: 50,
    offset: currentOffset,
  );
}
```

### 2. Image Caching
Images are cached by default with `Image.network()`.

### 3. State Management
Providers are used for efficient state updates.

### 4. Build Optimization
```bash
# Use --split-debug-info for smaller builds
flutter build web --release --split-debug-info=debug-info/ --target lib/main_web.dart

# Use tree-shaking for smaller bundle
flutter build web --release --tree-shake-icons --target lib/main_web.dart
```

## Security Considerations

### 1. HTTPS Only
Always deploy web app over HTTPS in production.

### 2. API Keys
Never hardcode API keys in web code. Use environment variables.

### 3. Input Validation
All user inputs are validated before sending to backend.

### 4. Token Storage
JWT tokens are stored in SharedPreferences (browser localStorage).

### 5. Session Timeout
Implement auto-logout after inactivity period.

## Testing

### Manual Testing Checklist

- [ ] User registration works
- [ ] User login works
- [ ] Device pairing works with valid code
- [ ] Device pairing fails with invalid code
- [ ] App search returns results
- [ ] App details display correctly
- [ ] Install button sends command
- [ ] Device selector shows all devices
- [ ] Device switching works
- [ ] Logout clears session
- [ ] Refresh reloads data

### Browser Compatibility

Tested on:
- Chrome 120+
- Firefox 120+
- Safari 17+
- Edge 120+

## Future Enhancements

- [ ] QR code scanning for device pairing
- [ ] Real-time install progress updates via WebSocket
- [ ] App categories browsing
- [ ] Recently updated apps section
- [ ] User favorites/wishlist
- [ ] Multi-device install (install on all devices)
- [ ] Install history
- [ ] Dark mode toggle in UI
- [ ] PWA offline support
- [ ] Push notifications for install status

## Support

For issues or questions:
- Check the main README.md
- Review backend/README.md for server setup
- Open an issue on GitHub
- Check browser console for errors

## License

Same as Florid main project.
