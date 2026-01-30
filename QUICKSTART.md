# Quick Start Guide - Web Companion Store

Get up and running with the Florid web companion store in 5 minutes!

## Prerequisites

- Node.js 16+ (for backend server)
- Flutter 3.x (for building web frontend)
- An Android device with Florid installed

## Step 1: Deploy Backend Server

### Option A: Local Development
```bash
cd backend
npm install
npm start
```

Backend runs at `http://localhost:3000`

### Option B: Deploy to Railway.app (Free)
1. Go to [railway.app](https://railway.app)
2. Sign up and create new project
3. Connect your GitHub repository
4. Select `backend` folder as root
5. Set environment variables:
   - `JWT_SECRET`: Generate a random 32-character string
   - `NODE_ENV`: production
6. Deploy!

## Step 2: Configure Web Frontend

Edit backend URLs in these files:

**lib/services/web_auth_service.dart:**
```dart
static const String _baseUrl =
    kDebugMode ? 'http://localhost:3000' : 'https://your-backend.railway.app';
```

**lib/services/web_device_service.dart:**
```dart
static const String _baseUrl =
    kDebugMode ? 'http://localhost:3000' : 'https://your-backend.railway.app';
```

## Step 3: Run Web Frontend

### Development
```bash
flutter run -d chrome --web-renderer html --target lib/main_web.dart
```

### Production Build
```bash
flutter build web --release --web-renderer html --target lib/main_web.dart
```

Deploy `build/web/` to:
- GitHub Pages
- Netlify
- Vercel
- Firebase Hosting

## Step 4: Pair Your Mobile Device

### On Web:
1. Open web app
2. Register/login
3. Click "Pair Device" button

### On Mobile:
1. Open Florid app
2. Go to Settings → Web Store Sync → Pair with Web Store
3. Note the information shown:
   - 6-digit pairing code (e.g., 123456)
   - Device ID (UUID)
   - Device Name (e.g., "Samsung Galaxy S21")

### Complete Pairing:
1. Enter the 6-digit code in web app
2. Copy/paste Device ID
3. Copy/paste Device Name
4. Click "Pair Device"
5. Wait for confirmation ✓

## Step 5: Install Apps Remotely

1. Browse or search for apps in web interface
2. Click on an app to view details
3. Ensure your device is selected in dropdown (top-right)
4. Click "Install on [Your Device]"
5. Check your mobile device for notification
6. Tap notification to start download/install

## Troubleshooting

### Backend Connection Failed
- Check backend is running
- Verify backend URL in service files
- Check CORS settings in backend
- Look at browser console for errors

### Device Pairing Failed
- Ensure pairing code hasn't expired (5 minutes)
- Verify Device ID and Device Name are correct
- Check mobile device has internet connection
- Try generating a new pairing code

### Install Not Received on Mobile
- Check device shows as "Active" (green icon) in web app
- Verify mobile app has internet connection
- Check WebSocket connection in mobile app
- Try refreshing device list in web app

### CORS Errors
Add your web app domain to backend CORS settings:

```javascript
// backend/server.js
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
  'http://localhost:3000',
  'https://your-web-app.netlify.app'  // Add your domain
];
```

## Architecture Overview

```
┌─────────────────┐
│   Web Browser   │
│  (Flutter Web)  │
└────────┬────────┘
         │ HTTP/WebSocket
         ↓
┌─────────────────┐
│ Backend Server  │
│   (Node.js)     │
└────────┬────────┘
         │ WebSocket
         ↓
┌─────────────────┐
│  Mobile Device  │
│  (Flutter App)  │
└─────────────────┘
```

## Security Notes

- Always use HTTPS in production
- Set a strong `JWT_SECRET` in backend
- Don't commit `.env` files
- Rate limiting is enabled by default
- Pairing codes expire after 5 minutes

## Next Steps

- Read [WEB_FRONTEND.md](WEB_FRONTEND.md) for detailed guide
- Check [backend/README.md](backend/README.md) for API docs
- See [README.md](README.md) for mobile app setup

## Support

- Open an issue on GitHub
- Check browser console for errors
- Review backend logs
- Test with backend running locally first

Happy remote installing! 🚀
