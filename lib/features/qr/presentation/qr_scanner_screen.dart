import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    _hasScanned = true;
    final value = barcode!.rawValue!;

    // Check if it's a patient QR code (format: medisync:patient:UUID)
    if (value.startsWith('medisync:patient:')) {
      final patientId = value.replaceFirst('medisync:patient:', '');
      _showResult(
        title: 'Patient Found',
        message: 'Navigate to patient details?',
        action: () => context.push('/patient/$patientId'),
      );
    } else {
      _showResult(title: 'QR Scanned', message: value, action: null);
    }
  }

  void _showResult({
    required String title,
    required String message,
    VoidCallback? action,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GlassTheme.cardBackground,
        title: Text(title, style: const TextStyle(color: GlassTheme.textWhite)),
        content: Text(message, style: TextStyle(color: GlassTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hasScanned = false);
            },
            child: const Text('Scan Again'),
          ),
          if (action != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                action();
              },
              child: const Text('Go'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Scan QR Code',
      actions: [
        IconButton(
          onPressed: () => _controller.toggleTorch(),
          icon: const Icon(LucideIcons.flashlight),
          tooltip: 'Toggle Flash',
        ),
        IconButton(
          onPressed: () => _controller.switchCamera(),
          icon: const Icon(LucideIcons.switchCamera),
          tooltip: 'Switch Camera',
        ),
      ],
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay with scan frame
          Center(
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: GlassTheme.neonCyan, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Point camera at a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GlassTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            ),
          ),

          // Bottom action button
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () => context.push('/qr-generate'),
              icon: const Icon(LucideIcons.qrCode),
              label: const Text('Generate QR Code'),
              style: FilledButton.styleFrom(
                backgroundColor: GlassTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
