# Testing Web-Mobile Pairing

## Same-Browser Testing (No Server Required)

The pairing feature now supports **same-browser testing** using localStorage. This means you can test the web-to-mobile pairing flow without a server backend by opening both web and mobile versions in the same browser.

### How It Works

- **Web version**: Uses localStorage to store pairing messages
- **Mobile version (in web)**: Reads from the same localStorage
- Messages are shared across browser tabs/windows in the same browser

### Steps to Test

1. **Open Web Version**
   ```bash
   flutter run -d chrome
   ```
   Or open `build/web/index.html` in your browser after building:
   ```bash
   flutter build web
   ```

2. **Open Mobile Version in Another Tab**
   - Open a new tab in the same browser
   - Navigate to the same URL (e.g., `http://localhost:8080`)
   - The mobile UI will show automatically on mobile-sized viewports
   - Or open developer tools and switch to mobile device emulation

3. **Start Pairing Process**
   
   **On Mobile Tab:**
   - Go to Settings → Pair with Web
   - Tap "Start Pairing"
   - Note the 6-digit code (e.g., 123456)
   
   **On Web Tab:**
   - Click "Enter Pairing Code"
   - Enter the 6-digit code from mobile
   - Click "Pair"
   - You should see "Successfully paired!" message

4. **Test Remote Installation**
   - Browse apps on the web tab
   - Click "Install" on any app
   - Switch to the mobile tab
   - You should see a notification about the install request

## Cross-Device Testing (Server Required)

To test pairing between actual separate devices (e.g., web browser on computer and mobile app on phone), you need to implement a server backend.

See `QUICK_START.md` section "Implementing a Server Backend (For Production)" for details on how to create a simple REST API server.

## Troubleshooting

### Pairing Fails

**Error:** "Timeout waiting for pairing response"

**Solutions:**
1. **Same-browser testing:**
   - Make sure both tabs are in the same browser (not different browsers)
   - Check browser console for localStorage errors
   - Try clearing browser localStorage and retry
   - Make sure JavaScript is enabled

2. **Cross-device testing:**
   - A server backend is required
   - The in-memory queue doesn't work across different devices
   - Implement the server as described in documentation

### Messages Not Appearing

**Check:**
1. Browser localStorage permissions (some browsers block it in private mode)
2. Both tabs are from the same origin (same protocol, domain, port)
3. No browser extensions blocking localStorage access

### Clear Pairing Data

To reset everything:
```javascript
// In browser console
localStorage.clear()
```

Or in the app, unpair and restart.

## Platform Detection

The app automatically detects the platform:
- `kIsWeb = true`: Uses localStorage for message passing
- `kIsWeb = false`: Uses in-memory queue (mobile app)

When both are running as web (same-browser testing), localStorage enables communication.

## Limitations

### Current Implementation (localStorage)
- ✅ Works in same browser across tabs
- ✅ No server required for testing
- ✅ Instant message passing
- ⚠️ Only works in same browser
- ⚠️ Doesn't work across different devices
- ⚠️ Requires JavaScript enabled
- ⚠️ May not work in private/incognito mode

### Production Implementation (Server Backend)
- ✅ Works across any devices
- ✅ Works across different networks
- ✅ Can persist pairing
- ✅ Supports multiple users
- ⚠️ Requires server setup and hosting
- ⚠️ Needs security implementation

## Example Server Implementation

For a quick test server, see the example in `QUICK_START.md`.

Here's a minimal Express.js server:

```javascript
const express = require('express');
const app = express();
app.use(express.json());

const messages = new Map();

app.post('/api/messages', (req, res) => {
  const { code, message } = req.body;
  if (!messages.has(code)) messages.set(code, []);
  messages.get(code).push(message);
  res.json({ success: true });
});

app.get('/api/messages/:code', (req, res) => {
  const msgs = messages.get(req.params.code) || [];
  res.json({ messages: msgs });
});

app.listen(3000, () => console.log('Server running on port 3000'));
```

Then update `pairing_service.dart` to use HTTP calls instead of localStorage.

## Security Notes

For same-browser testing:
- Pairing codes are still validated
- Messages have timestamps and expiry
- Device IDs are verified
- This is secure for testing purposes

For production with server:
- Use HTTPS/TLS
- Implement rate limiting
- Add authentication
- Validate all inputs
- Log suspicious activity

## Next Steps

1. Test same-browser pairing first
2. Verify the flow works correctly
3. When ready for production, implement server backend
4. Replace localStorage calls with HTTP API calls
5. Deploy server and update app configuration
