import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:medisynch/app/glass_theme.dart';
import 'package:medisynch/core/providers/auth_provider.dart';
import 'package:medisynch/core/services/auth_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: GlassTheme.textWhite),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: GlassTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: GlassTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _showEditProfileDialog(Map<String, dynamic>? profile) async {
    final nameController = TextEditingController(
      text: profile?['full_name'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: GlassTheme.textWhite),
        ),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: GlassTheme.textWhite),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: GlassTheme.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GlassTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: GlassTheme.neonCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await AuthService().updateProfile(fullName: name);
                ref.invalidate(userProfileProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlassTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Password',
          style: TextStyle(color: GlassTheme.textWhite),
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: GlassTheme.textWhite),
          decoration: InputDecoration(
            labelText: 'New Password',
            labelStyle: TextStyle(color: GlassTheme.textMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: GlassTheme.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: GlassTheme.neonCyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.length >= 6) {
                await AuthService().updatePassword(password);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: GlassTheme.deepBackground,
      appBar: AppBar(
        backgroundColor: GlassTheme.deepBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
              final profile = profileAsync.asData?.value;
              _showEditProfileDialog(profile);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: GlassTheme.neonCyan),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(color: GlassTheme.error)),
        ),
        data: (profile) => _buildContent(profile),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? profile) {
    final name = profile?['full_name'] ?? 'User';
    final email = profile?['email'] ?? '';
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // === Avatar Section ===
        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GlassTheme.neonCyan.withValues(alpha: 0.2),
                  border: Border.all(
                    color: GlassTheme.neonCyan.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: GlassTheme.neonCyan,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: GlassTheme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                email,
                style: TextStyle(color: GlassTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // === Account Section ===
        _buildSectionTitle('Account'),
        const SizedBox(height: 8),
        _buildMenuCard([
          _MenuItem(
            icon: LucideIcons.user,
            label: 'Edit Profile',
            onTap: () => _showEditProfileDialog(profile),
          ),
          _MenuItem(
            icon: LucideIcons.lock,
            label: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
          _MenuItem(
            icon: LucideIcons.bell,
            label: 'Notifications',
            onTap: () {},
          ),
        ]),

        const SizedBox(height: 24),

        // === Preferences Section ===
        _buildSectionTitle('Preferences'),
        const SizedBox(height: 8),
        _buildMenuCard([
          _MenuItem(
            icon: LucideIcons.palette,
            label: 'Appearance',
            onTap: () {},
          ),
          _MenuItem(icon: LucideIcons.globe, label: 'Language', onTap: () {}),
        ]),

        const SizedBox(height: 24),

        // === Support Section ===
        _buildSectionTitle('Support'),
        const SizedBox(height: 8),
        _buildMenuCard([
          _MenuItem(
            icon: LucideIcons.helpCircle,
            label: 'Help Center',
            onTap: () {},
          ),
          _MenuItem(
            icon: LucideIcons.messageCircle,
            label: 'Contact Us',
            onTap: () {},
          ),
        ]),

        const SizedBox(height: 24),

        // === Sign Out ===
        _buildMenuCard([
          _MenuItem(
            icon: LucideIcons.logOut,
            label: _isLoggingOut ? 'Signing out...' : 'Sign Out',
            onTap: _isLoggingOut ? null : _handleLogout,
            isDestructive: true,
          ),
        ]),

        const SizedBox(height: 40),
        Center(
          child: Text(
            'MediSync v1.0.0',
            style: TextStyle(
              color: GlassTheme.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: GlassTheme.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: GlassTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GlassTheme.glassBorder),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast)
                Divider(color: GlassTheme.glassBorder, height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    final color = item.isDestructive ? GlassTheme.error : GlassTheme.textWhite;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(color: color, fontSize: 15),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: GlassTheme.textMuted.withValues(alpha: 0.4),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });
}
