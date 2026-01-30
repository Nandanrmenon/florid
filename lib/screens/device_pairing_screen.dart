import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/settings_provider.dart';
import '../services/device_pairing_service.dart';
import '../widgets/m_list.dart';

/// Screen for pairing device with web companion store
class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  late DevicePairingService _pairingService;
  String? _deviceId;
  String? _deviceName;
  String? _pairingCode;
  String? _pairingUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePairing();
  }

  Future<void> _initializePairing() async {
    final settings = context.read<SettingsProvider>();
    _pairingService = DevicePairingService(settings);

    setState(() => _isLoading = true);

    try {
      _deviceId = await _pairingService.getDeviceId();
      _deviceName = await _pairingService.getDeviceName();
      _pairingCode = _pairingService.generatePairingCode();
      _pairingUrl = _pairingService.getPairingUrl(_pairingCode!, _deviceId!);
    } catch (e) {
      debugPrint('[DevicePairingScreen] Error initializing: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unpairDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text(
          'Are you sure you want to unpair this device? '
          'You will need to pair again to receive remote install requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _pairingService.unpairDevice();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device unpaired successfully')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _copyPairingCode() {
    if (_pairingCode != null) {
      Clipboard.setData(ClipboardData(text: _pairingCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pairing code copied to clipboard')),
      );
    }
  }

  void _copyDeviceId() {
    if (_deviceId != null) {
      Clipboard.setData(ClipboardData(text: _deviceId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device ID copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isPaired = settings.webSyncEnabled;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Web Store Pairing'),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pairing status card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(
                                isPaired
                                    ? Symbols.check_circle
                                    : Symbols.qr_code_scanner,
                                size: 48,
                                color: isPaired ? Colors.green : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isPaired
                                    ? 'Device Paired'
                                    : 'Pair with Web Store',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPaired
                                    ? 'This device is paired and can receive remote install requests'
                                    : 'Scan the QR code below on the web companion store to pair this device',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!isPaired && _pairingUrl != null) ...[
                        // QR Code for pairing
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _pairingUrl!,
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Scan this QR code',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Or use pairing code
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('Or enter this pairing code:'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _pairingCode ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 4,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Symbols.content_copy),
                                      onPressed: _copyPairingCode,
                                      tooltip: 'Copy pairing code',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Device information
                      Column(
                        spacing: 4,
                        children: [
                          MListHeader(title: 'Device Information'),
                          MListView(
                            items: [
                              MListItemData(
                                leading: const Icon(Symbols.smartphone),
                                title: 'Device Name',
                                subtitle: _deviceName ?? 'Unknown',
                                onTap: null,
                              ),
                              MListItemData(
                                leading: const Icon(Symbols.fingerprint),
                                title: 'Device ID',
                                subtitle: _deviceId ?? 'Unknown',
                                onTap: _copyDeviceId,
                                suffix: const Icon(Symbols.content_copy),
                              ),
                              if (isPaired)
                                MListItemData(
                                  leading: const Icon(Symbols.person),
                                  title: 'User ID',
                                  subtitle: settings.userId ?? 'Not set',
                                  onTap: null,
                                ),
                            ],
                          ),
                        ],
                      ),

                      if (isPaired) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _unpairDevice,
                          icon: const Icon(Symbols.link_off),
                          label: const Text('Unpair Device'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
