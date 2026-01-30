# Florid Backend Server

This is the backend server for Florid's web-mobile pairing and communication system.

## Features

- Pairing code generation for web-mobile device pairing
- WebSocket-based real-time communication
- Install request forwarding from web to mobile
- Download and install progress tracking

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### POST /api/pairing/generate
Generate a new pairing code for web-mobile pairing.

**Response:**
```json
{
  "pairingCode": "ABC12345",
  "sessionId": "uuid",
  "expiresIn": 300
}
```

### POST /api/pairing/join
Join a pairing session with a pairing code (mobile device).

**Request:**
```json
{
  "pairingCode": "ABC12345",
  "deviceId": "device-uuid",
  "deviceName": "My Phone"
}
```

**Response:**
```json
{
  "success": true,
  "sessionId": "uuid"
}
```

### GET /api/pairing/status/:sessionId
Check the pairing status of a session.

**Response:**
```json
{
  "paired": true,
  "mobileDeviceId": "device-uuid",
  "mobileDeviceName": "My Phone"
}
```

### POST /api/install/request
Send an install request to a paired mobile device.

**Request:**
```json
{
  "sessionId": "uuid",
  "packageName": "com.example.app",
  "appName": "Example App",
  "repositoryUrl": "https://f-droid.org/repo"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Install request sent to mobile device"
}
```

## WebSocket Messages

### Client to Server

**Register Device:**
```json
{
  "type": "register",
  "deviceId": "device-uuid",
  "sessionId": "session-uuid"
}
```

**Download Progress:**
```json
{
  "type": "download_progress",
  "packageName": "com.example.app",
  "progress": 0.75,
  "status": "downloading"
}
```

**Install Progress:**
```json
{
  "type": "install_progress",
  "packageName": "com.example.app",
  "status": "installing"
}
```

### Server to Client

**Install Request:**
```json
{
  "type": "install_request",
  "packageName": "com.example.app",
  "appName": "Example App",
  "repositoryUrl": "https://f-droid.org/repo",
  "timestamp": 1234567890
}
```

**Paired Notification:**
```json
{
  "type": "paired",
  "deviceId": "device-uuid",
  "deviceName": "My Phone"
}
```

## Environment Variables

- `PORT`: Server port (default: 3000)

## License

GPL-3.0
