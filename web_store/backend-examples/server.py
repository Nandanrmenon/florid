from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import threading
import time
import os

app = Flask(__name__)
CORS(app)

# In-memory storage (use a database like PostgreSQL or MongoDB in production)
pairings = {}  # { pairing_code: { 'device_id': str, 'expires_at': datetime } }
install_requests = {}  # { device_id: [requests] }
lock = threading.Lock()


def cleanup_expired_pairings():
    """Periodically clean up expired pairing codes"""
    while True:
        time.sleep(60)  # Check every minute
        with lock:
            now = datetime.now()
            expired = [code for code, data in pairings.items() 
                      if datetime.fromisoformat(data['expires_at'].replace('Z', '+00:00')) < now]
            for code in expired:
                del pairings[code]
                print(f'Expired pairing code: {code}')


# Start cleanup thread
cleanup_thread = threading.Thread(target=cleanup_expired_pairings, daemon=True)
cleanup_thread.start()


@app.route('/api/pair', methods=['POST'])
def pair_device():
    """Register a device with a pairing code"""
    try:
        data = request.json
        device_id = data.get('device_id')
        pairing_code = data.get('pairing_code')
        expires_at = data.get('expires_at')
        
        if not device_id or not pairing_code or not expires_at:
            return jsonify({
                'success': False,
                'error': 'Missing required fields'
            }), 400
        
        with lock:
            pairings[pairing_code] = {
                'device_id': device_id,
                'expires_at': expires_at
            }
        
        print(f'Device paired: {device_id} with code {pairing_code}')
        return jsonify({'success': True})
    
    except Exception as e:
        print(f'Pairing error: {e}')
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


@app.route('/api/pair/verify', methods=['POST'])
def verify_pairing():
    """Verify a pairing code and return device ID"""
    try:
        data = request.json
        pairing_code = data.get('pairing_code')
        
        if not pairing_code:
            return jsonify({
                'success': False,
                'error': 'Missing pairing code'
            }), 400
        
        with lock:
            pairing = pairings.get(pairing_code)
            
            if not pairing:
                return jsonify({
                    'success': False,
                    'error': 'Invalid pairing code'
                }), 404
            
            expires_at = datetime.fromisoformat(pairing['expires_at'].replace('Z', '+00:00'))
            if expires_at < datetime.now():
                del pairings[pairing_code]
                return jsonify({
                    'success': False,
                    'error': 'Pairing code expired'
                }), 404
            
            device_id = pairing['device_id']
        
        print(f'Pairing verified: {device_id}')
        return jsonify({
            'success': True,
            'device_id': device_id
        })
    
    except Exception as e:
        print(f'Verification error: {e}')
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


@app.route('/api/device/<device_id>/install', methods=['POST'])
def install_app(device_id):
    """Send an install request to a paired device"""
    try:
        data = request.json
        package_name = data.get('package_name')
        version_name = data.get('version_name')
        
        if not package_name or not version_name:
            return jsonify({
                'success': False,
                'error': 'Missing package_name or version_name'
            }), 400
        
        request_id = f'{int(time.time() * 1000)}-{id(data)}'
        install_request = {
            'id': request_id,
            'package_name': package_name,
            'version_name': version_name,
            'timestamp': datetime.now().isoformat()
        }
        
        with lock:
            if device_id not in install_requests:
                install_requests[device_id] = []
            install_requests[device_id].append(install_request)
        
        print(f'Install request for device {device_id}: {package_name} v{version_name}')
        return jsonify({'success': True, 'request_id': request_id})
    
    except Exception as e:
        print(f'Install request error: {e}')
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


@app.route('/api/device/<device_id>/requests', methods=['GET'])
def get_requests(device_id):
    """Get pending install requests for a device"""
    try:
        with lock:
            requests = install_requests.get(device_id, [])
        return jsonify({'requests': requests})
    
    except Exception as e:
        print(f'Get requests error: {e}')
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


@app.route('/api/device/<device_id>/requests/<request_id>', methods=['DELETE'])
def acknowledge_request(device_id, request_id):
    """Acknowledge a processed install request"""
    try:
        with lock:
            requests = install_requests.get(device_id, [])
            filtered = [r for r in requests if r['id'] != request_id]
            install_requests[device_id] = filtered
        
        print(f'Request {request_id} acknowledged for device {device_id}')
        return jsonify({'success': True})
    
    except Exception as e:
        print(f'Acknowledge error: {e}')
        return jsonify({'success': False, 'error': 'Internal server error'}), 500


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    with lock:
        return jsonify({
            'status': 'ok',
            'pairings': len(pairings),
            'devices_with_requests': len(install_requests)
        })


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 3000))
    print(f'Florid Web Store Backend running on port {port}')
    print(f'Health check: http://localhost:{port}/health')
    app.run(host='0.0.0.0', port=port, debug=False)
