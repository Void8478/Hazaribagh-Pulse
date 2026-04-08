import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';

class ProfileMenuTiles extends ConsumerWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ProfileMenuTiles({super.key, required this.onLogout, required this.onDeleteAccount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Appearance Section
        _buildSectionTitle(context, 'Appearance'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 18), label: Text('System')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18), label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref.read(themeProvider.notifier).setTheme(newSelection.first);
              },
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Settings & Privacy Section
        _buildSectionTitle(context, 'Settings & Privacy'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildTile(context, Icons.person_outline, 'Edit Profile', () => context.push('/edit-profile')),
                _buildDivider(context),
                _buildTile(context, Icons.notifications_none, 'Notifications', () => context.push('/notifications')),
                _buildDivider(context),
                _buildTile(context, Icons.security, 'Privacy Settings', () => context.push('/privacy')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Help & Support Section
        _buildSectionTitle(context, 'Help & Support'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildTile(context, Icons.help_outline, 'Help Center', () => context.push('/help')),
                _buildDivider(context),
                _buildTile(context, Icons.feedback_outlined, 'Send Feedback', () => context.push('/feedback')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onTap: onLogout,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Delete Account
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FilledButton.icon(
            onPressed: onDeleteAccount,
            icon: const Icon(Icons.delete_forever, size: 20),
            label: const Text('Delete Account'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }
}
