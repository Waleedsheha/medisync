import 'package:flutter/material.dart';

class PremiumActionButton extends StatelessWidget {
  const PremiumActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary,
        scheme.tertiary,
      ],
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      elevation: disabled ? 0 : 10,
      shadowColor: scheme.primary.withValues(alpha: 0.35),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(
                  colors: [
                    scheme.surfaceContainerHighest,
                    scheme.surfaceContainerHighest,
                  ],
                )
              : gradient,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: (disabled ? scheme.outlineVariant : scheme.onPrimary)
                .withValues(alpha: disabled ? 0.35 : 0.18),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: disabled ? scheme.onSurfaceVariant : scheme.onPrimary,
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color:
                              disabled ? scheme.onSurfaceVariant : scheme.onPrimary,
                        ),
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
