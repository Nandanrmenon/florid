# Web Store Feature

This document describes the new web store feature that allows users to pair their mobile device with a web interface and install apps remotely.

## Overview

The web store feature enables users to:
1. Browse F-Droid apps from a web interface
2. Pair their mobile device with the web interface using a QR code
3. Install apps on their mobile device by clicking "Install" on the web interface
4. Receive notifications on their mobile device when an install is requested
5. Track download and installation progress

## Architecture

The feature consists of three main components:

### 1. Backend Server (`/server`)
- Node.js/Express server with WebSocket support
- Handles pairing code generation and session management
- Forwards install requests from web to mobile devices
- Relays download/install progress updates

### 2. Web Interface
- Flutter web application
- Displays F-Droid apps in a grid layout
- Generates pairing QR codes
- Sends install requests to paired mobile devices
- Shows real-time download/install progress

### 3. Mobile App
- Flutter Android application
- Scans pairing QR codes
- Receives install notifications
- Downloads and installs APK files
- Reports progress back to web interface

## Setup

### Backend Server

1. Navigate to the server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

3. Start the server:
```bash
npm start
```

The server will run on `http://localhost:3000` by default.

For production deployment, consider:
- Using a process manager like PM2
- Setting up SSL/TLS for secure connections
- Configuring environment variables for production settings

### Web Interface

1. Configure server URL in `lib/main.dart`:
```dart
service.init(
  serverUrl: 'https://your-server.com',  // Update this
  wsUrl: 'wss://your-server.com',        // Update this
);
```

2. Build the web app:
```bash
flutter build web
```

3. Deploy the built files from `build/web` to your web server.

### Mobile App

The mobile app will automatically use the configured server URLs. No additional setup is required beyond normal app installation.

## Usage

### Pairing Devices

1. **On Web**:
   - Click the phone icon in the top-right corner
   - A pairing code and QR code will be displayed
   - Keep this page open until pairing is complete

2. **On Mobile**:
   - Open the app menu (three dots in top-right)
   - Select "Pair with Web"
   - Scan the QR code or enter the pairing code manually
   - Wait for confirmation

### Installing Apps

1. **On Web**:
   - Browse or search for apps
   - Click "Install" on any app
   - The install request will be sent to your mobile device

2. **On Mobile**:
   - You'll receive a notification
   - Tap the notification to view install progress
   - The app will download and install automatically
   - Approve the installation when prompted by Android

## Security Considerations

- Pairing codes expire after 5 minutes
- Each pairing session is unique and temporary
- No Google services are used
- All communication goes through your own server
- Consider implementing authentication for production use
- Use HTTPS/WSS in production to encrypt communications

## Configuration

### Server Configuration

Edit `server/index.js` to configure:
- Port number (default: 3000)
- Session expiry time (default: 5 minutes)
- CORS settings

### Mobile/Web Configuration

Edit `lib/main.dart` to configure:
- Server HTTP URL
- Server WebSocket URL

## Troubleshooting

### Pairing Issues

- **Pairing code expired**: Generate a new code
- **Mobile can't connect**: Check server URL configuration
- **QR code won't scan**: Enter the code manually

### Install Issues

- **Install request not received**: Check WebSocket connection
- **Download fails**: Verify internet connection and repository access
- **Installation fails**: Check Android permissions (REQUEST_INSTALL_PACKAGES)

### Server Issues

- **Server won't start**: Check if port 3000 is available
- **WebSocket connection fails**: Verify firewall settings
- **CORS errors**: Update CORS configuration in server

## API Reference

See `server/README.md` for detailed API documentation.

## Future Enhancements

Potential improvements for future versions:
- Multi-device pairing support
- Install queue management
- Remote uninstall capability
- App update notifications
- User authentication
- Persistent sessions
- Progressive Web App (PWA) support

## License

GPL-3.0 - Same as the main Florid project
