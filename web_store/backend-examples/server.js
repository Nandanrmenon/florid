const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (use a database like MongoDB or PostgreSQL in production)
const pairings = new Map(); // { pairingCode: { deviceId, expiresAt } }
const installRequests = new Map(); // { deviceId: [requests] }

// Clean up expired pairings periodically
setInterval(() => {
  const now = new Date();
  for (const [code, pairing] of pairings.entries()) {
    if (new Date(pairing.expiresAt) < now) {
      pairings.delete(code);
      console.log(`Expired pairing code: ${code}`);
    }
  }
}, 60000); // Check every minute

// API Endpoints

/**
 * Register a device with a pairing code
 * POST /api/pair
 */
app.post('/api/pair', (req, res) => {
  try {
    const { device_id, pairing_code, expires_at } = req.body;
    
    if (!device_id || !pairing_code || !expires_at) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing required fields' 
      });
    }
    
    pairings.set(pairing_code, { 
      deviceId: device_id, 
      expiresAt: expires_at 
    });
    
    console.log(`Device paired: ${device_id} with code ${pairing_code}`);
    res.json({ success: true });
  } catch (error) {
    console.error('Pairing error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * Verify a pairing code and return device ID
 * POST /api/pair/verify
 */
app.post('/api/pair/verify', (req, res) => {
  try {
    const { pairing_code } = req.body;
    
    if (!pairing_code) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing pairing code' 
      });
    }
    
    const pairing = pairings.get(pairing_code);
    
    if (!pairing) {
      return res.status(404).json({ 
        success: false, 
        error: 'Invalid pairing code' 
      });
    }
    
    if (new Date(pairing.expiresAt) < new Date()) {
      pairings.delete(pairing_code);
      return res.status(404).json({ 
        success: false, 
        error: 'Pairing code expired' 
      });
    }
    
    console.log(`Pairing verified: ${pairing.deviceId}`);
    res.json({ 
      success: true, 
      device_id: pairing.deviceId 
    });
  } catch (error) {
    console.error('Verification error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * Send an install request to a paired device
 * POST /api/device/:device_id/install
 */
app.post('/api/device/:device_id/install', (req, res) => {
  try {
    const { device_id } = req.params;
    const { package_name, version_name } = req.body;
    
    if (!package_name || !version_name) {
      return res.status(400).json({ 
        success: false, 
        error: 'Missing package_name or version_name' 
      });
    }
    
    if (!installRequests.has(device_id)) {
      installRequests.set(device_id, []);
    }
    
    const request = {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      package_name,
      version_name,
      timestamp: new Date().toISOString()
    };
    
    installRequests.get(device_id).push(request);
    
    console.log(`Install request for device ${device_id}: ${package_name} v${version_name}`);
    res.json({ success: true, request_id: request.id });
  } catch (error) {
    console.error('Install request error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * Get pending install requests for a device
 * GET /api/device/:device_id/requests
 */
app.get('/api/device/:device_id/requests', (req, res) => {
  try {
    const { device_id } = req.params;
    const requests = installRequests.get(device_id) || [];
    res.json({ requests });
  } catch (error) {
    console.error('Get requests error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * Acknowledge a processed install request
 * DELETE /api/device/:device_id/requests/:request_id
 */
app.delete('/api/device/:device_id/requests/:request_id', (req, res) => {
  try {
    const { device_id, request_id } = req.params;
    const requests = installRequests.get(device_id) || [];
    const filtered = requests.filter(r => r.id !== request_id);
    installRequests.set(device_id, filtered);
    
    console.log(`Request ${request_id} acknowledged for device ${device_id}`);
    res.json({ success: true });
  } catch (error) {
    console.error('Acknowledge error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    pairings: pairings.size,
    devices_with_requests: installRequests.size
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Florid Web Store Backend running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});
