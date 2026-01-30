// Configuration
const SERVER_URL = 'https://florid-web-store.example.com'; // Replace with your server URL
const FDROID_API_URL = 'https://f-droid.org/repo';

// State
let deviceId = null;
let pairingCode = null;
let isPaired = false;
let apps = [];

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadSavedPairing();
});

// Load saved pairing from localStorage
function loadSavedPairing() {
    const saved = localStorage.getItem('florid_pairing');
    if (saved) {
        try {
            const data = JSON.parse(saved);
            if (data.deviceId && data.pairingCode) {
                deviceId = data.deviceId;
                pairingCode = data.pairingCode;
                isPaired = true;
                showPairedState();
            }
        } catch (e) {
            console.error('Error loading saved pairing:', e);
        }
    }
}

// Save pairing to localStorage
function savePairing() {
    localStorage.setItem('florid_pairing', JSON.stringify({
        deviceId,
        pairingCode,
        timestamp: new Date().toISOString()
    }));
}

// Pair device with code
async function pairDevice() {
    const codeInput = document.getElementById('pairing-code');
    const code = codeInput.value.trim();
    
    if (code.length !== 6) {
        showStatus('Please enter a valid 6-digit pairing code', 'error');
        return;
    }
    
    showStatus('Pairing...', 'info');
    
    try {
        const response = await fetch(`${SERVER_URL}/api/pair/verify`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ pairing_code: code })
        });
        
        if (response.ok) {
            const data = await response.json();
            deviceId = data.device_id;
            pairingCode = code;
            isPaired = true;
            savePairing();
            showPairedState();
            showStatus('Successfully paired with device!', 'success');
        } else {
            showStatus('Invalid or expired pairing code', 'error');
        }
    } catch (error) {
        console.error('Pairing error:', error);
        showStatus('Connection error. Please check your internet connection.', 'error');
    }
}

// Show QR scanner (placeholder - would need QR library)
function showQRScanner() {
    alert('QR scanning requires a camera-enabled device and additional setup. Please use the pairing code for now.');
}

// Unpair device
function unpairDevice() {
    if (confirm('Disconnect from this device?')) {
        deviceId = null;
        pairingCode = null;
        isPaired = false;
        localStorage.removeItem('florid_pairing');
        showUnpairedState();
    }
}

// Show paired state
function showPairedState() {
    document.getElementById('pairing-section').style.display = 'none';
    document.getElementById('app-browser-section').style.display = 'block';
    document.getElementById('device-info-section').style.display = 'block';
    document.getElementById('device-info-text').textContent = `Device ID: ${deviceId}`;
    loadApps();
}

// Show unpaired state
function showUnpairedState() {
    document.getElementById('pairing-section').style.display = 'block';
    document.getElementById('app-browser-section').style.display = 'none';
    document.getElementById('device-info-section').style.display = 'none';
    document.getElementById('pairing-code').value = '';
}

// Show status message
function showStatus(message, type) {
    const statusEl = document.getElementById('pairing-status');
    statusEl.textContent = message;
    statusEl.className = `status-${type}`;
    statusEl.style.display = 'block';
}

// Load F-Droid apps
async function loadApps() {
    try {
        // For demo purposes, showing a few popular F-Droid apps
        // In production, this would fetch from F-Droid's index
        apps = [
            {
                packageName: 'org.fdroid.fdroid',
                name: 'F-Droid',
                summary: 'Application manager for Android',
                icon: 'https://f-droid.org/repo/icons-640/org.fdroid.fdroid.1020050.png',
                version: '1.20.0'
            },
            {
                packageName: 'org.mozilla.fennec_fdroid',
                name: 'Fennec F-Droid',
                summary: 'Web browser based on Mozilla Firefox',
                icon: 'https://f-droid.org/repo/icons-640/org.mozilla.fennec_fdroid.1160000.png',
                version: '132.0'
            },
            {
                packageName: 'com.termux',
                name: 'Termux',
                summary: 'Terminal emulator and Linux environment',
                icon: 'https://f-droid.org/repo/icons-640/com.termux.1180.png',
                version: '0.118.1'
            },
            {
                packageName: 'org.videolan.vlc',
                name: 'VLC',
                summary: 'Media player for video and audio',
                icon: 'https://f-droid.org/repo/icons-640/org.videolan.vlc.14010205.png',
                version: '4.0.1'
            },
            {
                packageName: 'org.telegram.messenger',
                name: 'Telegram FOSS',
                summary: 'Messaging app',
                icon: 'https://f-droid.org/repo/icons-640/org.telegram.messenger.35990.png',
                version: '11.5.3'
            },
            {
                packageName: 'com.nextcloud.client',
                name: 'Nextcloud',
                summary: 'Sync files with Nextcloud server',
                icon: 'https://f-droid.org/repo/icons-640/com.nextcloud.client.30460499.png',
                version: '3.30.0'
            }
        ];
        
        displayApps(apps);
    } catch (error) {
        console.error('Error loading apps:', error);
    }
}

// Display apps
function displayApps(appsToDisplay) {
    const appList = document.getElementById('app-list');
    appList.innerHTML = '';
    
    if (appsToDisplay.length === 0) {
        appList.innerHTML = '<p>No apps found</p>';
        return;
    }
    
    appsToDisplay.forEach(app => {
        const appCard = createAppCard(app);
        appList.appendChild(appCard);
    });
}

// Create app card element
function createAppCard(app) {
    const card = document.createElement('div');
    card.className = 'app-card';
    
    card.innerHTML = `
        <img src="${app.icon}" alt="${app.name} icon" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%2264%22 height=%2264%22><rect fill=%22%23ccc%22 width=%2264%22 height=%2264%22/></svg>'">
        <h3>${app.name}</h3>
        <p>${app.summary}</p>
        <div class="version">Version: ${app.version}</div>
        <button class="install-button" onclick="installApp('${app.packageName}', '${app.version}')">
            Install on Phone
        </button>
    `;
    
    return card;
}

// Search apps
function searchApps() {
    const query = document.getElementById('search-input').value.toLowerCase();
    const filtered = apps.filter(app => 
        app.name.toLowerCase().includes(query) ||
        app.summary.toLowerCase().includes(query) ||
        app.packageName.toLowerCase().includes(query)
    );
    displayApps(filtered);
}

// Install app on paired device
async function installApp(packageName, versionName) {
    if (!isPaired || !deviceId) {
        alert('Please pair your device first');
        return;
    }
    
    try {
        const response = await fetch(`${SERVER_URL}/api/device/${deviceId}/install`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                package_name: packageName,
                version_name: versionName
            })
        });
        
        if (response.ok) {
            alert(`Install request sent to your phone!\nApp: ${packageName}\nCheck your phone for the download notification.`);
        } else {
            alert('Failed to send install request. Please try again.');
        }
    } catch (error) {
        console.error('Install error:', error);
        alert('Connection error. Please check your internet connection.');
    }
}
