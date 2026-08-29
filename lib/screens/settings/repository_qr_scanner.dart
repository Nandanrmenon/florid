import 'package:florid/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
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
      appBar: AppBar(
        title: Text(localizations.scan),
        backgroundColor: Colors.black45,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                QRView(
                  key: _qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Theme.of(context).colorScheme.primary,
                    borderRadius: 12,
                    borderLength: 30,
                    borderWidth: 5,
                    cutOutSize: 250,
                  ),
                  formatsAllowed: const [BarcodeFormat.qrcode],
                ),
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations.point_camera_qr,
                        style: Theme.of(context).textTheme.labelMedium,
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
