const express = require('express');
const http = require('http');
const socketio = require('socket.io');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketio(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST']
  }
});

app.use(cors());
app.use(express.json());

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests from this IP, please try again later.'
});

app.use('/api/', apiLimiter);

const users = new Map();
const devices = new Map();
const pairingCodes = new Map();
const installQueue = new Map();
const deviceConnections = new Map();

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

function generateToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: '30d' });
}

function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  const token = authHeader.substring(7);
  const decoded = verifyToken(token);
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  req.userId = decoded.userId;
  next();
}

app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    for (const user of users.values()) {
      if (user.username === username) {
        return res.status(409).json({ error: 'Username already exists' });
      }
    }
    const userId = uuidv4();
    const passwordHash = await bcrypt.hash(password, 10);
    users.set(userId, { id: userId, username, passwordHash, createdAt: new Date().toISOString() });
    const token = generateToken(userId);
    res.json({ success: true, userId, token, username });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password required' });
    }
    let user = null;
    for (const u of users.values()) {
      if (u.username === username) {
        user = u;
        break;
      }
    }
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    const token = generateToken(user.id);
    res.json({ success: true, userId: user.id, token, username: user.username });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/devices/pair', authenticateUser, (req, res) => {
  try {
    const { deviceId, deviceName, pairingCode } = req.body;
    if (!deviceId || !deviceName) {
      return res.status(400).json({ error: 'Device ID and name required' });
    }
    if (pairingCode) {
      const pairing = pairingCodes.get(pairingCode);
      if (!pairing || pairing.deviceId !== deviceId) {
        return res.status(400).json({ error: 'Invalid pairing code' });
      }
      if (new Date() > new Date(pairing.expiresAt)) {
        pairingCodes.delete(pairingCode);
        return res.status(400).json({ error: 'Pairing code expired' });
      }
      pairingCodes.delete(pairingCode);
    }
    devices.set(deviceId, {
      deviceId, userId: req.userId, deviceName,
      pairedAt: new Date().toISOString(),
      lastSeen: new Date().toISOString(), isActive: false
    });
    console.log(`Device paired: ${deviceId} for user ${req.userId}`);
    res.json({ success: true, deviceId, message: 'Device paired successfully' });
  } catch (error) {
    console.error('Pairing error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/devices', authenticateUser, (req, res) => {
  try {
    const userDevices = [];
    for (const device of devices.values()) {
      if (device.userId === req.userId) {
        userDevices.push({
          deviceId: device.deviceId, deviceName: device.deviceName,
          pairedAt: device.pairedAt, lastSeen: device.lastSeen, isActive: device.isActive
        });
      }
    }
    res.json({ success: true, devices: userDevices });
  } catch (error) {
    console.error('List devices error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/devices/:deviceId', authenticateUser, (req, res) => {
  try {
    const { deviceId } = req.params;
    const device = devices.get(deviceId);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (device.userId !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    const socket = deviceConnections.get(deviceId);
    if (socket) {
      socket.disconnect();
      deviceConnections.delete(deviceId);
    }
    devices.delete(deviceId);
    installQueue.delete(deviceId);
    res.json({ success: true, message: 'Device unpaired successfully' });
  } catch (error) {
    console.error('Unpair error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/install', authenticateUser, (req, res) => {
  try {
    const { deviceId, packageName, appName, iconUrl, versionName } = req.body;
    if (!deviceId || !packageName || !appName) {
      return res.status(400).json({ error: 'Device ID, package name, and app name required' });
    }
    const device = devices.get(deviceId);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (device.userId !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    const installCommand = {
      packageName, appName, timestamp: new Date().toISOString(),
      sourceDevice: 'web', iconUrl, versionName
    };
    const socket = deviceConnections.get(deviceId);
    if (socket) {
      socket.emit('install-request', installCommand);
      console.log(`Sent install request to ${deviceId}: ${packageName}`);
      res.json({ success: true, message: 'Install request sent to device', sent: true });
    } else {
      if (!installQueue.has(deviceId)) {
        installQueue.set(deviceId, []);
      }
      installQueue.get(deviceId).push(installCommand);
      console.log(`Queued install request for ${deviceId}: ${packageName}`);
      res.json({ success: true, message: 'Install request queued (device offline)', sent: false });
    }
  } catch (error) {
    console.error('Install error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/install/queue/:deviceId', authenticateUser, (req, res) => {
  try {
    const { deviceId } = req.params;
    const device = devices.get(deviceId);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (device.userId !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    const queue = installQueue.get(deviceId) || [];
    res.json({ success: true, queue });
  } catch (error) {
    console.error('Get queue error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

io.on('connection', (socket) => {
  console.log('New WebSocket connection:', socket.id);
  let authenticatedDeviceId = null;
  socket.on('authenticate', ({ deviceId, authToken }) => {
    console.log('Authentication attempt:', deviceId);
    const decoded = verifyToken(authToken);
    if (!decoded) {
      socket.emit('error', { message: 'Invalid or expired token' });
      socket.disconnect();
      return;
    }
    const device = devices.get(deviceId);
    if (!device || device.userId !== decoded.userId) {
      socket.emit('error', { message: 'Device not found or unauthorized' });
      socket.disconnect();
      return;
    }
    authenticatedDeviceId = deviceId;
    deviceConnections.set(deviceId, socket);
    device.isActive = true;
    device.lastSeen = new Date().toISOString();
    socket.emit('authenticated', { success: true });
    console.log('Device authenticated:', deviceId);
    const queue = installQueue.get(deviceId) || [];
    if (queue.length > 0) {
      console.log(`Sending ${queue.length} queued commands to ${deviceId}`);
      queue.forEach(command => socket.emit('install-request', command));
      installQueue.delete(deviceId);
    }
  });
  socket.on('install-ack', ({ packageName, timestamp }) => {
    console.log('Install acknowledged:', packageName);
  });
  socket.on('install-status-update', (data) => {
    console.log('Install status update:', data);
    io.emit(`install-status-${data.packageName}`, data);
  });
  socket.on('ping', () => socket.emit('pong'));
  socket.on('disconnect', () => {
    console.log('WebSocket disconnected:', socket.id);
    if (authenticatedDeviceId) {
      deviceConnections.delete(authenticatedDeviceId);
      const device = devices.get(authenticatedDeviceId);
      if (device) {
        device.isActive = false;
        device.lastSeen = new Date().toISOString();
      }
    }
  });
});

app.get('/', (req, res) => {
  res.json({
    name: 'Florid Backend API', version: '1.0.0', status: 'running',
    endpoints: {
      auth: { register: 'POST /api/auth/register', login: 'POST /api/auth/login' },
      devices: { pair: 'POST /api/devices/pair', list: 'GET /api/devices', unpair: 'DELETE /api/devices/:deviceId' },
      install: { send: 'POST /api/install', queue: 'GET /api/install/queue/:deviceId' }
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Florid backend server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
