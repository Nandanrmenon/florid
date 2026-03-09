import 'package:florid/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class RepositoryQRScanner extends StatefulWidget {
  final Function(String url) onScan;

  const RepositoryQRScanner({super.key, required this.onScan});

  @override
  State<RepositoryQRScanner> createState() => _RepositoryQRScannerState();
}

class _RepositoryQRScannerState extends State<RepositoryQRScanner> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'RepositoryQRScanner');
  QRViewController? _cameraController;
  bool _isProcessing = false;

  bool _isValidUrl(String text) {
    try {
      Uri.parse(text);
      return text.startsWith('http://') || text.startsWith('https://');
    } catch (e) {
      return false;
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    _cameraController = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isProcessing) return;

      final String? rawValue = scanData.code;
      debugPrint(
        '[QR Scanner] Barcode value: $rawValue, type: ${scanData.format}',
      );

      if (rawValue != null && _isValidUrl(rawValue)) {
        debugPrint('[QR Scanner] Valid URL detected: $rawValue');
        _isProcessing = true;
        _cameraController?.pauseCamera();
        final onScan = widget.onScan;
        if (!mounted) return;

        // Close the QR scanner page first.
        Navigator.pop(context);

        // Trigger callback after the pop completes.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onScan(rawValue);
        });
      } else if (rawValue != null) {
        debugPrint('[QR Scanner] Invalid URL format: $rawValue');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.scan)),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              children: [
                QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  formatsAllowed: const [BarcodeFormat.qrcode],
                ),
                // Overlay with scanning frame and instructions
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          localizations.point_camera_qr,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                        ),
                      ),
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            localizations.tap_keyboard_enter_url,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
