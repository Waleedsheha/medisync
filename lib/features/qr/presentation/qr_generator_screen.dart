import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/widgets/app_scaffold.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  String? _selectedPatientId;
  String? _selectedPatientName;

  // For demo purposes - in production this would come from a patient provider
  final _demoPatients = [
    {'id': 'demo-1', 'name': 'John Doe', 'mrn': 'MRN-001'},
    {'id': 'demo-2', 'name': 'Jane Smith', 'mrn': 'MRN-002'},
    {'id': 'demo-3', 'name': 'Ahmed Hassan', 'mrn': 'MRN-003'},
  ];

  String get _qrData {
    if (_selectedPatientId == null) return '';
    return 'medisync:patient:$_selectedPatientId';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Generate QR Code',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlassTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GlassTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Patient', style: GlassTheme.textTheme.titleMedium),
                const SizedBox(height: 12),
                ...List.generate(_demoPatients.length, (i) {
                  final p = _demoPatients[i];
                  final isSelected = _selectedPatientId == p['id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPatientId = p['id'];
                        _selectedPatientName = p['name'];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GlassTheme.neonCyan.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? GlassTheme.neonCyan
                              : GlassTheme.glassBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            color: isSelected
                                ? GlassTheme.neonCyan
                                : GlassTheme.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name']!,
                                  style: TextStyle(
                                    color: GlassTheme.textWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  p['mrn']!,
                                  style: TextStyle(
                                    color: GlassTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              LucideIcons.check,
                              color: GlassTheme.neonCyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // QR Code display
          if (_selectedPatientId != null) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _selectedPatientName ?? '',
              textAlign: TextAlign.center,
              style: GlassTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Scan to view patient details',
              textAlign: TextAlign.center,
              style: GlassTheme.textTheme.bodySmall,
            ),

            const SizedBox(height: 24),

            // Share button
            FilledButton.icon(
              onPressed: () {
                // ignore: deprecated_member_use
                Share.share(
                  'View patient in MediSync: $_qrData',
                  subject: 'Patient QR Code',
                );
              },
              icon: const Icon(LucideIcons.share2),
              label: const Text('Share QR Code'),
              style: FilledButton.styleFrom(
                backgroundColor: GlassTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ] else ...[
            // Empty state
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.qrCode,
                    size: 64,
                    color: GlassTheme.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a patient to generate QR code',
                    style: GlassTheme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
