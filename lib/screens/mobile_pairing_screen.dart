import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../services/pairing_service.dart';

/// Mobile pairing screen to scan QR code or enter pairing code
class MobilePairingScreen extends StatefulWidget {
  const MobilePairingScreen({super.key});

  @override
  State<MobilePairingScreen> createState() => _MobilePairingScreenState();
}

class _MobilePairingScreenState extends State<MobilePairingScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _error;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    controller?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processPairingCode(scanData.code!);
      }
    });
  }

  Future<void> _processPairingCode(String code) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final pairingService = context.read<PairingService>();
      await pairingService.joinPairingSession(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully paired with web device!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pairing failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enterCodeManually() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pairing Code'),
        content: TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            hintText: 'ABC12345',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _codeController.text.toUpperCase());
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );

    if (code != null && code.isNotEmpty) {
      _processPairingCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair with Web'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _enterCodeManually,
            tooltip: 'Enter code manually',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Theme.of(context).colorScheme.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Pairing...'),
                      ],
                    )
                  else if (_error != null)
                    Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Scan the QR code from the web store',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _enterCodeManually,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter Code Manually'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
