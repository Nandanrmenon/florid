import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/pairing_service.dart';

/// Web pairing screen to generate QR code for mobile pairing
class WebPairingScreen extends StatefulWidget {
  const WebPairingScreen({super.key});

  @override
  State<WebPairingScreen> createState() => _WebPairingScreenState();
}

class _WebPairingScreenState extends State<WebPairingScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePairingCode();
  }

  Future<void> _generatePairingCode() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pairingService = context.read<PairingService>();
      await pairingService.generatePairingCode();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair Mobile Device'),
      ),
      body: Consumer<PairingService>(
        builder: (context, pairingService, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating pairing code...'),
                ],
              ),
            );
          }

          if (_error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generatePairingCode,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (pairingService.isPaired) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Successfully Paired!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connected to: ${pairingService.pairedDeviceName}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Start Browsing'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      await pairingService.unpair();
                      _generatePairingCode();
                    },
                    child: const Text('Unpair'),
                  ),
                ],
              ),
            );
          }

          final pairingCode = pairingService.pairingCode;
          if (pairingCode == null) {
            return const Center(child: Text('No pairing code available'));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Scan QR Code with Mobile App',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: pairingCode,
                      version: QrVersions.auto,
                      size: 300,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Or enter this code manually:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pairingCode,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for mobile device to connect...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _generatePairingCode,
                    child: const Text('Generate New Code'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
