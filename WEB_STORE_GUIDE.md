# Web Store Feature Guide

## Overview

The Florid Web Store feature allows you to browse and install F-Droid apps remotely from a web browser. When you click "Install" on the web store, your phone receives a notification and automatically downloads and installs the app.

## Architecture

```
┌─────────────┐         ┌─────────────────┐         ┌─────────────┐
│   Web       │         │  Self-Hosted    │         │   Mobile    │
│  Browser    │ ◄─────► │   Backend       │ ◄─────► │    App      │
│  (Desktop)  │         │    Server       │         │  (Android)  │
└─────────────┘         └─────────────────┘         └─────────────┘
```

**Key Components:**

1. **Web Interface** (`web_store/` directory)
   - Static HTML/CSS/JavaScript
   - Browse apps, enter pairing code
   - Send install requests to backend

2. **Backend Server** (`web_store/backend-examples/`)
   - Node.js or Python implementation
   - Manages device pairing
   - Routes install requests between web and mobile

3. **Mobile App** (Flutter)
   - Polls backend every 5 seconds for requests
   - Shows notifications for install requests
   - Downloads and installs APKs

## Quick Start Guide

### Step 1: Set Up Backend Server

Choose Node.js or Python:

**Node.js:**
```bash
cd web_store/backend-examples
npm install
npm start
```

**Python:**
```bash
cd web_store/backend-examples
pip install -r requirements.txt
python server.py
```

The server will start on `http://localhost:3000`

### Step 2: Configure Mobile App

1. Open Florid app on your Android device
2. Go to **Settings** → **Web Store Pairing**
3. Enable **Web Pairing**
4. Note the 6-digit pairing code displayed

### Step 3: Open Web Store

1. Edit `web_store/script.js` and set `SERVER_URL` to your server:
   ```javascript
   const SERVER_URL = 'http://localhost:3000'; // Or your server URL
   ```

2. Open `web_store/index.html` in your web browser

3. Enter the 6-digit pairing code from your phone

4. Click "Pair Device"

### Step 4: Install Apps Remotely

1. Browse or search for apps in the web store
2. Click "Install on Phone" for any app
3. Your phone will receive a notification
4. Tap the notification to see download progress
5. Once downloaded, tap "Install"

## Features

### Security

- ✅ **No Google Services**: Uses self-hosted backend instead of Firebase
- ✅ **Pairing Codes Expire**: Codes expire after 15 minutes
- ✅ **Device-Specific**: Each device has a unique anonymous ID
- ✅ **User Control**: Can be disabled at any time in settings

### User Experience

- ✅ **QR Code Support**: Scan QR code instead of typing code (planned)
- ✅ **Progress Tracking**: See download/install progress on phone
- ✅ **Notifications**: Get notified when install request arrives
- ✅ **Web Search**: Search for apps directly in web browser

### Technical

- ✅ **HTTP Polling**: Mobile app polls every 5 seconds
- ✅ **Offline Capable**: Web store shows cached app list
- ✅ **Multi-Device**: Pair multiple devices (one at a time per browser)
- ✅ **Stateless Backend**: Easy to scale horizontally

## Network Configuration

### Local Network (Easiest)

1. Run backend server on your computer: `npm start`
2. Find your computer's IP address:
   - **Windows**: `ipconfig`
   - **Mac/Linux**: `ifconfig` or `ip addr`
3. Update mobile app server URL: Settings → Web Store Pairing
4. Use `http://YOUR_IP:3000` (e.g., `http://192.168.1.100:3000`)

### Internet (Remote Access)

**Option 1: Cloud Hosting**
- Deploy backend to Heroku, Railway, or DigitalOcean
- Use the public URL in web store and mobile app

**Option 2: ngrok (Development)**
```bash
ngrok http 3000
```
Use the ngrok URL (e.g., `https://abc123.ngrok.io`)

**Option 3: VPN**
- Use Tailscale, ZeroTier, or WireGuard
- Access your home network remotely

## Troubleshooting

### Phone Not Receiving Install Requests

**Check:**
1. Is web pairing enabled in mobile app?
2. Is the backend server running?
3. Is the server URL correct in mobile app settings?
4. Is the phone connected to internet?
5. Did you pair successfully (green checkmark)?

**Debug:**
- Check backend server logs: `npm start` or `python server.py`
- Check mobile app logs: `adb logcat | grep WebPairingService`
- Try the health check: `curl http://localhost:3000/health`

### Pairing Code Not Working

**Causes:**
- Code expired (valid for 15 minutes)
- Backend server not running
- Wrong server URL

**Solutions:**
- Generate a new code in mobile app
- Verify backend server is running: `curl http://localhost:3000/health`
- Double-check server URL in web store `script.js`

### Downloads Not Starting

**Check:**
1. Is app available in F-Droid repository?
2. Does phone have storage space?
3. Are download permissions granted?
4. Is internet connection working?

**Debug:**
- Check notification service logs
- Verify download provider is working
- Test downloading an app directly in the mobile app first

## Production Deployment

⚠️ **Important**: The example servers use in-memory storage and are not production-ready.

### Required for Production

1. **Database**: PostgreSQL, MongoDB, or Redis
2. **HTTPS**: SSL certificate (Let's Encrypt is free)
3. **Authentication**: API keys or OAuth
4. **Rate Limiting**: Prevent abuse
5. **Monitoring**: Logging and error tracking
6. **Backups**: Regular database backups

### Recommended Hosting

- **Backend**: Heroku, Railway, Render, DigitalOcean, AWS, Google Cloud
- **Web Store**: Netlify, Vercel, GitHub Pages, Cloudflare Pages
- **Database**: Managed PostgreSQL (Supabase, Railway, AWS RDS)

### Example: Deploy to Railway

1. Create account at [railway.app](https://railway.app)
2. New Project → Deploy from GitHub
3. Select your forked Florid repository
4. Set build command: `cd web_store/backend-examples && npm install`
5. Set start command: `npm start`
6. Add PostgreSQL database
7. Copy the public URL
8. Update `SERVER_URL` in web store and mobile app

## Privacy & Security

### What Gets Shared

- Device ID (random, anonymous)
- Pairing code (temporary, expires)
- Package names of apps you want to install
- Timestamps of requests

### What Does NOT Get Shared

- Your personal information
- App usage data
- Phone contents
- Contacts or messages
- Location

### Data Storage

- **Backend**: Pairing codes and install requests only
- **Mobile**: Device ID and server URL in local storage
- **Web**: Pairing info in browser localStorage

### Recommendations

- Use a trusted backend server (self-host or vetted provider)
- Use HTTPS for all connections
- Regenerate pairing codes regularly
- Disable web pairing when not in use

## API Reference

See `web_store/README.md` for complete API documentation.

### Endpoints

- `POST /api/pair` - Register device
- `POST /api/pair/verify` - Verify pairing code
- `POST /api/device/:id/install` - Send install request
- `GET /api/device/:id/requests` - Get pending requests
- `DELETE /api/device/:id/requests/:rid` - Acknowledge request
- `GET /health` - Health check

## Development

### Adding New Features

**Web Store:**
- Edit `web_store/index.html`, `styles.css`, `script.js`
- No build step required

**Mobile App:**
- Edit files in `lib/services/` and `lib/screens/`
- Run `flutter pub get` after adding dependencies
- Test on Android device or emulator

**Backend:**
- Modify `server.js` or `server.py`
- Restart server to apply changes

### Testing

```bash
# Test backend API
curl http://localhost:3000/health

# Test pairing
curl -X POST http://localhost:3000/api/pair \
  -H "Content-Type: application/json" \
  -d '{"device_id":"test","pairing_code":"123456","expires_at":"2024-12-31T23:59:59Z"}'

# Mobile app logs
adb logcat | grep -E "(WebPairingService|RemoteInstall)"
```

## Contributing

Contributions are welcome! Areas for improvement:

- [ ] WebSocket support for real-time updates
- [ ] QR code scanning in web browser
- [ ] Better app discovery and categories
- [ ] Install multiple apps at once
- [ ] App installation queue
- [ ] Push notifications (optional)
- [ ] Multi-language support
- [ ] Better error messages

## License

GPL-3.0 (same as Florid project)

## Support

- GitHub Issues: [github.com/Nandanrmenon/florid/issues](https://github.com/Nandanrmenon/florid/issues)
- Discussions: Use GitHub Discussions for questions
- Documentation: See `web_store/README.md` and `web_store/backend-examples/README.md`

## Credits

- Florid: Modern F-Droid client
- F-Droid: Free and open source Android app repository
- Community: Contributors and testers

---

**Note**: This is an unofficial feature and is not affiliated with or endorsed by F-Droid.
