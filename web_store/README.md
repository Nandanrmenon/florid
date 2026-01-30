# Florid Web Store

A web interface for remotely installing F-Droid apps on your Android device running the Florid app.

## Features

- Browse F-Droid apps from a web browser
- Pair your phone with the web store using a pairing code or QR code
- Send install requests to your phone remotely
- Get notifications on your phone when an install request is received
- Track download and installation progress

## How It Works

1. **Mobile App**: Enable web pairing in the Florid mobile app settings
2. **Web Interface**: Open the web store and enter the pairing code
3. **Install Apps**: Browse apps and click "Install on Phone"
4. **Phone Notification**: Your phone receives a notification to download the app
5. **Download & Install**: Tap the notification to see download progress and install

## Setup

### Prerequisites

- A self-hosted backend server (Node.js, Python, or any language)
- The Florid mobile app installed on your Android device

### Backend Server

The web store requires a backend server to facilitate communication between the web interface and mobile app. The server needs to implement these API endpoints:

#### POST `/api/pair`
Register a device with a pairing code.

**Request:**
```json
{
  "device_id": "unique-device-id",
  "pairing_code": "123456",
  "expires_at": "2024-01-30T20:00:00Z"
}
```

**Response:**
```json
{
  "success": true
}
```

#### POST `/api/pair/verify`
Verify a pairing code and return device ID.

**Request:**
```json
{
  "pairing_code": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "device_id": "unique-device-id"
}
```

#### POST `/api/device/{device_id}/install`
Send an install request to a paired device.

**Request:**
```json
{
  "package_name": "org.fdroid.fdroid",
  "version_name": "1.20.0"
}
```

**Response:**
```json
{
  "success": true
}
```

#### GET `/api/device/{device_id}/requests`
Get pending install requests for a device (polled by mobile app every 5 seconds).

**Response:**
```json
{
  "requests": [
    {
      "id": "request-id",
      "package_name": "org.fdroid.fdroid",
      "version_name": "1.20.0",
      "timestamp": "2024-01-30T20:00:00Z"
    }
  ]
}
```

#### DELETE `/api/device/{device_id}/requests/{request_id}`
Acknowledge a processed install request.

**Response:**
```json
{
  "success": true
}
```

### Example Backend (Node.js/Express)

```javascript
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// In-memory storage (use a database in production)
const pairings = new Map(); // { pairingCode: { deviceId, expiresAt } }
const installRequests = new Map(); // { deviceId: [requests] }

app.post('/api/pair', (req, res) => {
  const { device_id, pairing_code, expires_at } = req.body;
  pairings.set(pairing_code, { deviceId: device_id, expiresAt: expires_at });
  res.json({ success: true });
});

app.post('/api/pair/verify', (req, res) => {
  const { pairing_code } = req.body;
  const pairing = pairings.get(pairing_code);
  
  if (pairing && new Date(pairing.expiresAt) > new Date()) {
    res.json({ success: true, device_id: pairing.deviceId });
  } else {
    res.status(404).json({ success: false, error: 'Invalid or expired code' });
  }
});

app.post('/api/device/:device_id/install', (req, res) => {
  const { device_id } = req.params;
  const { package_name, version_name } = req.body;
  
  if (!installRequests.has(device_id)) {
    installRequests.set(device_id, []);
  }
  
  installRequests.get(device_id).push({
    id: Date.now().toString(),
    package_name,
    version_name,
    timestamp: new Date().toISOString()
  });
  
  res.json({ success: true });
});

app.get('/api/device/:device_id/requests', (req, res) => {
  const { device_id } = req.params;
  const requests = installRequests.get(device_id) || [];
  res.json({ requests });
});

app.delete('/api/device/:device_id/requests/:request_id', (req, res) => {
  const { device_id, request_id } = req.params;
  const requests = installRequests.get(device_id) || [];
  const filtered = requests.filter(r => r.id !== request_id);
  installRequests.set(device_id, filtered);
  res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

### Hosting the Web Store

1. Update `SERVER_URL` in `script.js` to point to your backend server
2. Host the web store files (`index.html`, `styles.css`, `script.js`) on any web server
3. Access the web store from any modern web browser

### Mobile App Configuration

1. Open Florid app settings
2. Navigate to "Web Store Pairing"
3. Enable web pairing
4. Note the pairing code or scan the QR code on the web interface
5. The app will poll for install requests every 5 seconds

## Security Considerations

- Pairing codes expire after 15 minutes
- Use HTTPS for both web interface and backend server
- Consider implementing authentication for the backend API
- Device IDs are randomly generated and stored locally
- Install requests are deleted after being acknowledged

## Privacy

- No Google services are used
- All communication goes through your self-hosted server
- No analytics or tracking
- Device IDs are anonymous and can be regenerated

## Development

The web store is a static HTML/CSS/JS application. To develop:

1. Edit the files in the `web_store` directory
2. Serve them using any local web server (e.g., `python -m http.server`)
3. Point to your development backend server

## License

Same as the main Florid project (GPL-3.0)

## Contributing

Contributions are welcome! Please follow the main project's contribution guidelines.
