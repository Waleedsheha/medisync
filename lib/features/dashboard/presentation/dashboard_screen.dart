import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medisynch/app/glass_theme.dart';
import '../../notifications/data/notifications_repository.dart';

import '../../../core/widgets/app_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'MediSync',
      showBottomNavBar: true,
      actions: [
        const _NotificationBell(),
        IconButton(
          onPressed: () => context.push('/profile'),
          icon: const Icon(LucideIcons.user, size: 22),
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/qr-scan'),
        backgroundColor: GlassTheme.neonCyan,
        child: const Icon(LucideIcons.qrCode, color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // === Header Card ===
          _HeaderCard(),
          const SizedBox(height: 20),

          // === Search Bar ===
          _SearchBar(),
          const SizedBox(height: 24),

          // === Honeycomb Grid ===
          _HoneycombGrid(animationController: _controller),

          const SizedBox(height: 120), // Bottom padding for FAB
        ],
      ),
    );
  }
}

// === Honeycomb Grid ===
class _HoneycombGrid extends StatelessWidget {
  final AnimationController animationController;

  const _HoneycombGrid({required this.animationController});

  // Rearranged for complete cycle pattern
  static const _modules = [
    _ModuleData(
      LucideIcons.building,
      'Hospitals',
      '/hospitals',
      GlassTheme.neonCyan,
    ),
    _ModuleData(
      LucideIcons.stethoscope,
      'Clinics',
      '/clinics',
      GlassTheme.neonPurple,
    ),
    _ModuleData(
      LucideIcons.archive,
      'Archive',
      '/archive',
      GlassTheme.textGrey,
    ),
    _ModuleData(
      LucideIcons.calendarClock,
      'Plans',
      '/plans',
      GlassTheme.neonBlue,
    ),
    _ModuleData(
      LucideIcons.messageSquare,
      'Chat',
      '/chat',
      GlassTheme.neonBlue,
    ),
    _ModuleData(LucideIcons.network, 'Online', '/cases', GlassTheme.neonCyan),
    _ModuleData(LucideIcons.video, 'Conference', '/', GlassTheme.neonPurple),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing
        final availableWidth = constraints.maxWidth;
        final hexSize = availableWidth / 2.6; // 40% bigger hexagons
        final hexHeight = hexSize * 0.9;
        final overlap = hexSize * 0.80;

        // True grid width: from leftmost to rightmost hex
        // Middle row extends: -0.5*overlap on left, +1.5*overlap + hexSize on right
        final gridTrueWidth = overlap * 2 + hexSize;
        final centerX = availableWidth / 2;
        final baseX = centerX - gridTrueWidth / 2 + overlap * 0.5;
        final totalHeight = hexHeight * 2.5;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // CENTER TILE (Video Conference)
              Positioned(
                top: hexHeight * 0.78,
                left: baseX + overlap * 0.5,
                child: _AnimatedHexTile(
                  module: _modules[6],
                  size: hexSize,
                  animation: _staggeredAnimation(6),
                ),
              ),
              // Top left (position 0)
              Positioned(
                top: 0,
                left: baseX,
                child: _AnimatedHexTile(
                  module: _modules[0],
                  size: hexSize,
                  animation: _staggeredAnimation(0),
                ),
              ),
              // Top right (position 1)
              Positioned(
                top: 0,
                left: baseX + overlap,
                child: _AnimatedHexTile(
                  module: _modules[1],
                  size: hexSize,
                  animation: _staggeredAnimation(1),
                ),
              ),

              // Middle right (position 2)
              Positioned(
                top: hexHeight * 0.78,
                left: baseX + overlap * 1.5,
                child: _AnimatedHexTile(
                  module: _modules[2],
                  size: hexSize,
                  animation: _staggeredAnimation(2),
                ),
              ),

              // Bottom right (position 3)
              Positioned(
                top: hexHeight * 1.56,
                left: baseX + overlap,
                child: _AnimatedHexTile(
                  module: _modules[3],
                  size: hexSize,
                  animation: _staggeredAnimation(3),
                ),
              ),

              // Bottom left (position 4)
              Positioned(
                top: hexHeight * 1.56,
                left: baseX,
                child: _AnimatedHexTile(
                  module: _modules[4],
                  size: hexSize,
                  animation: _staggeredAnimation(4),
                ),
              ),

              // Middle left (position 5)
              Positioned(
                top: hexHeight * 0.78,
                left: baseX - overlap * 0.5,
                child: _AnimatedHexTile(
                  module: _modules[5],
                  size: hexSize,
                  animation: _staggeredAnimation(5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Animation<double> _staggeredAnimation(int index) {
    final start = index * 0.1;
    final end = (start + 0.4).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ),
    );
  }
}

// === Animated Hexagon Tile with Hover & Tap Effects ===
class _AnimatedHexTile extends StatefulWidget {
  final _ModuleData module;
  final double size;
  final Animation<double> animation;

  const _AnimatedHexTile({
    required this.module,
    required this.size,
    required this.animation,
  });

  @override
  State<_AnimatedHexTile> createState() => _AnimatedHexTileState();
}

class _AnimatedHexTileState extends State<_AnimatedHexTile> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animation.value,
          child: Opacity(
            opacity: widget.animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            context.push(widget.module.route);
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.92 : (_isHovered ? 1.08 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size * 0.9,
              child: CustomPaint(
                painter: _HexagonPainter(
                  fillColor: _isHovered
                      ? GlassTheme.cardBackground.withValues(alpha: 0.9)
                      : GlassTheme.cardBackground,
                  borderColor: _isHovered
                      ? widget.module.color.withValues(alpha: 0.7)
                      : widget.module.color.withValues(alpha: 0.3),
                  glowColor: _isHovered ? widget.module.color : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.module.color.withValues(
                            alpha: _isHovered ? 0.25 : 0.15,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: _isHovered
                              ? [
                                  BoxShadow(
                                    color: widget.module.color.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: -2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          widget.module.icon,
                          color: widget.module.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.module.title,
                        style: TextStyle(
                          color: _isHovered
                              ? GlassTheme.textWhite
                              : GlassTheme.textWhite.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: _isHovered
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === Hexagon Painter with Optional Glow ===
class _HexagonPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final Color? glowColor;

  _HexagonPainter({
    required this.fillColor,
    required this.borderColor,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getHexagonPath(size);

    // Glow effect on hover
    if (glowColor != null) {
      final glowPaint = Paint()
        ..color = glowColor!.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, glowPaint);
    }

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  Path _getHexagonPath(Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;
    final radius = math.min(w, h) / 2 * 0.9;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - (math.pi / 6);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.glowColor != glowColor;
  }
}

// === Module Data ===
class _ModuleData {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  const _ModuleData(this.icon, this.title, this.route, this.color);
}

// === Tips Card with Rotating Info ===
class _HeaderCard extends StatefulWidget {
  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard> {
  int _currentTip = 0;

  static const _tips = [
    _TipData(
      LucideIcons.lightbulb,
      'Did you know?',
      'Swipe on patient cards to quickly access their plans.',
    ),
    _TipData(
      LucideIcons.zap,
      'Quick Tip',
      'Use the search bar to find patients by name or MRN.',
    ),
    _TipData(
      LucideIcons.sparkles,
      'AI Assistant',
      'Get help with drug interactions and dosing calculations.',
    ),
    _TipData(
      LucideIcons.heart,
      'Stay Organized',
      'Pin your most visited hospitals for quick access.',
    ),
    _TipData(
      LucideIcons.shield,
      'Security',
      'Your patient data is encrypted and HIPAA compliant.',
    ),
    _TipData(
      LucideIcons.clock,
      'Reminder',
      'Check the Plans section for upcoming appointments.',
    ),
    _TipData(
      LucideIcons.pill,
      'Drug Library',
      'Access thousands of medications with dosing info.',
    ),
    _TipData(
      LucideIcons.archive,
      'Archive',
      'Store and organize patient documents securely.',
    ),
    _TipData(
      LucideIcons.calculator,
      'Calculators',
      'Medical calculators for GFR, BMI, and more.',
    ),
    _TipData(
      LucideIcons.video,
      'Video Consult',
      'Start video conferences with colleagues instantly.',
    ),
    _TipData(
      LucideIcons.cloud,
      'Cloud Sync',
      'Your data syncs across all your devices.',
    ),
    _TipData(
      LucideIcons.wifiOff,
      'Offline Mode',
      'Access patient data even without internet.',
    ),
    _TipData(
      LucideIcons.bell,
      'Notifications',
      'Get alerts for critical lab results and messages.',
    ),
    _TipData(
      LucideIcons.users,
      'Collaboration',
      'Share patient notes with your care team.',
    ),
    _TipData(
      LucideIcons.fileText,
      'Reports',
      'Generate PDF reports for patient handoffs.',
    ),
    _TipData(
      LucideIcons.trendingUp,
      'Analytics',
      'Track patient outcomes and clinic metrics.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTipRotation();
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentTip = (_currentTip + 1) % _tips.length;
        });
        _startTipRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_currentTip];

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTip = (_currentTip + 1) % _tips.length;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlassTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GlassTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: GlassTheme.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      tip.icon,
                      key: ValueKey(_currentTip),
                      color: GlassTheme.neonCyan,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Column(
                      key: ValueKey(_currentTip),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip.title, style: GlassTheme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          tip.subtitle,
                          style: GlassTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Horizontal dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tips.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentTip ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: i == _currentTip
                        ? GlassTheme.neonCyan
                        : GlassTheme.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TipData(this.icon, this.title, this.subtitle);
}

// === Search Bar ===
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: GlassTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTheme.glassBorder),
      ),
      child: TextField(
        style: const TextStyle(color: GlassTheme.textWhite),
        decoration: InputDecoration(
          hintText: 'Search patient, hospital, unit...',
          hintStyle: TextStyle(color: GlassTheme.textMuted),
          prefixIcon: Icon(
            LucideIcons.search,
            color: GlassTheme.textMuted,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationsCountProvider);

    return Stack(
      children: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(LucideIcons.bell, size: 22),
        ),
        countAsync.when(
          data: (count) {
            if (count == 0) return const SizedBox.shrink();
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: GlassTheme.neonCyan,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
