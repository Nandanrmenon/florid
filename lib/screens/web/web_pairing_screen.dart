import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../services/web_device_service.dart';

/// Screen for pairing a new device
class WebPairingScreen extends StatefulWidget {
  const WebPairingScreen({super.key});

  @override
  State<WebPairingScreen> createState() => _WebPairingScreenState();
}

class _WebPairingScreenState extends State<WebPairingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _pairingCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    _pairingCodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePairing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final deviceService = context.read<WebDeviceService>();
    final success = await deviceService.pairDevice(
      _deviceIdController.text,
      _deviceNameController.text,
      _pairingCodeController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device paired successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pairing failed. Check your code and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Device'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Symbols.qr_code_scanner,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pair Your Device',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Open Florid on your mobile device, go to Settings → Web Store Sync → Pair with Web Store, and enter the information below:',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _pairingCodeController,
                  decoration: const InputDecoration(
                    labelText: '6-Digit Pairing Code',
                    prefixIcon: Icon(Symbols.pin),
                    border: OutlineInputBorder(),
                    helperText: 'Enter the code shown on your mobile device',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter pairing code';
                    }
                    if (value.length != 6) {
                      return 'Pairing code must be 6 digits';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  enabled: !_isLoading,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceIdController,
                  decoration: const InputDecoration(
                    labelText: 'Device ID',
                    prefixIcon: Icon(Symbols.fingerprint),
                    border: OutlineInputBorder(),
                    helperText: 'Copy from your mobile device',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter device ID';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _deviceNameController,
                  decoration: const InputDecoration(
                    labelText: 'Device Name',
                    prefixIcon: Icon(Symbols.smartphone),
                    border: OutlineInputBorder(),
                    helperText: 'Copy from your mobile device',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter device name';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _handlePairing,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Pair Device'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
