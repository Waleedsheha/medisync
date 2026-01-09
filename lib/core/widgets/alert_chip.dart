import 'package:flutter/material.dart';

enum MiniAlert { ok, review, critical, missing }

extension MiniAlertX on MiniAlert {
  String get text => switch (this) {
        MiniAlert.ok => 'طبيعي',
        MiniAlert.review => 'راجع القيم',
        MiniAlert.critical => 'قيمة حرجة',
        MiniAlert.missing => 'بيانات ناقصة',
      };

  IconData get icon => switch (this) {
        MiniAlert.ok => Icons.check_circle,
        MiniAlert.review => Icons.warning_amber,
        MiniAlert.critical => Icons.report,
        MiniAlert.missing => Icons.info,
      };
}

class AlertChip extends StatelessWidget {
  const AlertChip(this.alert, {super.key});
  final MiniAlert alert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (bg, fg) = switch (alert) {
      MiniAlert.ok => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      MiniAlert.review => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      MiniAlert.critical => (scheme.errorContainer, scheme.onErrorContainer),
      MiniAlert.missing => (scheme.surfaceContainerHighest, scheme.onSurface),
    };

    return Chip(
      avatar: Icon(alert.icon, size: 18, color: fg),
      label: Text(
        alert.text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    );
  }
}
