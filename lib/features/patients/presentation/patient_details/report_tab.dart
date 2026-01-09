import 'package:flutter/material.dart';

import 'shared_widgets.dart';

Future<void> showPatientQrDialog({
  required BuildContext context,
  required String mrn,
  required ToastFn toast,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: const Text('Patient QR'),
        content: Container(
          height: 240,
          width: 240,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_2, size: 92, color: scheme.primary),
                const SizedBox(height: 8),
                Text(mrn.isNotEmpty ? mrn : '—', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              toast('Print');
            },
            child: const Text('Print'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              toast('Share');
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class ReportTab extends StatelessWidget {
  const ReportTab({
    super.key,
    required this.mrn,
    required this.onPdf,
    required this.onPrint,
    required this.onShare,
    required this.toast,
  });

  final String mrn;
  final VoidCallback onPdf;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final ToastFn toast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Report, QR & Print'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: scheme.primary),
                        const SizedBox(height: 6),
                        Text(
                          'QR (placeholder)\n${mrn.isNotEmpty ? mrn : '—'}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    /* Expanded(
                      child: FilledButton.icon(
                        onPressed: onPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Report'),
                      ),
                    ),*/
                    //Report button removed
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showPatientQrDialog(
                          context: context,
                          mrn: mrn,
                          toast: toast,
                        ),
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('QR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
