import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/glass_theme.dart';
import '../presentation/glass_bottom_bar.dart';

/// Main app scaffold with clean dark background
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBottomNavBar = false,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBottomNavBar;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/ai')) return 1;
    if (location.startsWith('/drugs')) return 2;
    if (location.startsWith('/medicalc')) return 3;
    if (location.startsWith('/infusions')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/ai');
        break;
      case 2:
        context.go('/drugs');
        break;
      case 3:
        context.go('/medicalc');
        break;
      case 4:
        context.go('/infusions');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: GlassTheme.deepBackground,
      appBar: AppBar(
        backgroundColor: GlassTheme.deepBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: GlassTheme.textTheme.headlineMedium),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: actions,
        iconTheme: const IconThemeData(color: GlassTheme.textWhite, size: 22),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: GlassTheme.textWhite,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: body,
      bottomNavigationBar: showBottomNavBar
          ? GlassBottomBar(
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(index, context),
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
