const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors());
app.use(express.json());

// Store pairing sessions
const pairingSessions = new Map();
// Store WebSocket connections by device ID
const deviceConnections = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Generate a pairing code
app.post('/api/pairing/generate', (req, res) => {
  const pairingCode = uuidv4().substring(0, 8).toUpperCase();
  const sessionId = uuidv4();
  
  pairingSessions.set(pairingCode, {
    sessionId,
    webDeviceId: null,
    mobileDeviceId: null,
    createdAt: Date.now(),
    expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes
    paired: false
  });
  
  console.log(`Generated pairing code: ${pairingCode}`);
  
  res.json({
    pairingCode,
    sessionId,
    expiresIn: 300 // seconds
  });
});

// Join a pairing session (mobile device)
app.post('/api/pairing/join', (req, res) => {
  const { pairingCode, deviceId, deviceName } = req.body;
  
  if (!pairingCode || !deviceId) {
    return res.status(400).json({ error: 'Missing pairingCode or deviceId' });
  }
  
  const session = pairingSessions.get(pairingCode);
  
  if (!session) {
    return res.status(404).json({ error: 'Invalid pairing code' });
  }
  
  if (session.expiresAt < Date.now()) {
    pairingSessions.delete(pairingCode);
    return res.status(410).json({ error: 'Pairing code expired' });
  }
  
  if (session.paired) {
    return res.status(409).json({ error: 'Session already paired' });
  }
  
  session.mobileDeviceId = deviceId;
  session.mobileDeviceName = deviceName || 'Mobile Device';
  session.paired = true;
  
  // Notify web client if connected
  const webConnection = deviceConnections.get(session.sessionId);
  if (webConnection && webConnection.readyState === WebSocket.OPEN) {
    webConnection.send(JSON.stringify({
      type: 'paired',
      deviceId,
      deviceName: session.mobileDeviceName
    }));
  }
  
  console.log(`Mobile device ${deviceId} joined session ${session.sessionId}`);
  
  res.json({
    success: true,
    sessionId: session.sessionId
  });
});

// Get pairing status
app.get('/api/pairing/status/:sessionId', (req, res) => {
  const { sessionId } = req.params;
  
  const session = Array.from(pairingSessions.values()).find(s => s.sessionId === sessionId);
  
  if (!session) {
    return res.status(404).json({ error: 'Session not found' });
  }
  
  res.json({
    paired: session.paired,
    mobileDeviceId: session.mobileDeviceId,
    mobileDeviceName: session.mobileDeviceName
  });
});

// Send install request to mobile device
app.post('/api/install/request', (req, res) => {
  const { sessionId, packageName, appName, repositoryUrl } = req.body;
  
  if (!sessionId || !packageName) {
    return res.status(400).json({ error: 'Missing required parameters' });
  }
  
  const session = Array.from(pairingSessions.values()).find(s => s.sessionId === sessionId);
  
  if (!session || !session.paired) {
    return res.status(404).json({ error: 'Session not found or not paired' });
  }
  
  // Send to mobile device via WebSocket
  const mobileConnection = deviceConnections.get(session.mobileDeviceId);
  
  if (!mobileConnection || mobileConnection.readyState !== WebSocket.OPEN) {
    return res.status(503).json({ error: 'Mobile device not connected' });
  }
  
  const installRequest = {
    type: 'install_request',
    packageName,
    appName: appName || packageName,
    repositoryUrl: repositoryUrl || 'https://f-droid.org/repo',
    timestamp: Date.now()
  };
  
  mobileConnection.send(JSON.stringify(installRequest));
  
  console.log(`Sent install request for ${packageName} to mobile device ${session.mobileDeviceId}`);
  
  res.json({
    success: true,
    message: 'Install request sent to mobile device'
  });
});

// WebSocket connection handler
wss.on('connection', (ws, req) => {
  let deviceId = null;
  let sessionId = null;
  
  console.log('New WebSocket connection');
  
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      switch (data.type) {
        case 'register':
          deviceId = data.deviceId;
          sessionId = data.sessionId;
          
          deviceConnections.set(deviceId, ws);
          
          if (sessionId) {
            deviceConnections.set(sessionId, ws);
          }
          
          console.log(`Registered device: ${deviceId} (session: ${sessionId})`);
          
          ws.send(JSON.stringify({
            type: 'registered',
            deviceId
          }));
          break;
          
        case 'download_progress':
          // Forward download progress to web client if connected
          if (sessionId) {
            const webConnection = deviceConnections.get(sessionId);
            if (webConnection && webConnection !== ws && webConnection.readyState === WebSocket.OPEN) {
              webConnection.send(JSON.stringify({
                type: 'download_progress',
                packageName: data.packageName,
                progress: data.progress,
                status: data.status
              }));
            }
          }
          break;
          
        case 'install_progress':
          // Forward install progress to web client if connected
          if (sessionId) {
            const webConnection = deviceConnections.get(sessionId);
            if (webConnection && webConnection !== ws && webConnection.readyState === WebSocket.OPEN) {
              webConnection.send(JSON.stringify({
                type: 'install_progress',
                packageName: data.packageName,
                status: data.status
              }));
            }
          }
          break;
          
        case 'ping':
          ws.send(JSON.stringify({ type: 'pong' }));
          break;
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });
  
  ws.on('close', () => {
    if (deviceId) {
      deviceConnections.delete(deviceId);
      console.log(`Device disconnected: ${deviceId}`);
    }
    if (sessionId) {
      deviceConnections.delete(sessionId);
    }
  });
  
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
});

// Clean up expired pairing sessions every minute
setInterval(() => {
  const now = Date.now();
  for (const [code, session] of pairingSessions.entries()) {
    if (session.expiresAt < now) {
      pairingSessions.delete(code);
      console.log(`Cleaned up expired pairing code: ${code}`);
    }
  }
}, 60000);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Florid server listening on port ${PORT}`);
  console.log(`WebSocket server ready`);
});
