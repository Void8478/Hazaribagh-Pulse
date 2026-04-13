import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_provider.dart';

class ProfileMenuTiles extends ConsumerWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onOpenAdminPanel;
  final bool isLoggingOut;
  final bool isDeletingAccount;
  final bool actionsDisabled;
  final bool showAdminPanel;

  const ProfileMenuTiles({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
    this.onOpenAdminPanel,
    this.isLoggingOut = false,
    this.isDeletingAccount = false,
    this.actionsDisabled = false,
    this.showAdminPanel = false,
  });

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
              onSelectionChanged: actionsDisabled
                  ? null
                  : (Set<ThemeMode> newSelection) {
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
                _buildTile(
                  context,
                  Icons.person_outline,
                  'Edit Profile',
                  () => context.push('/edit-profile'),
                  enabled: !actionsDisabled,
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  Icons.notifications_none,
                  'Notifications',
                  () => context.push('/notifications'),
                  enabled: !actionsDisabled,
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  Icons.security,
                  'Privacy Settings',
                  () => context.push('/privacy'),
                  enabled: !actionsDisabled,
                ),
                if (showAdminPanel && onOpenAdminPanel != null) ...[
                  _buildDivider(context),
                  _buildTile(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'Admin Panel',
                    onOpenAdminPanel!,
                    enabled: !actionsDisabled,
                  ),
                ],
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
                _buildTile(
                  context,
                  Icons.help_outline,
                  'Help Center',
                  () => context.push('/help'),
                  enabled: !actionsDisabled,
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  Icons.feedback_outlined,
                  'Send Feedback',
                  () => context.push('/feedback'),
                  enabled: !actionsDisabled,
                ),
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
              color: colorScheme.errorContainer.withValues(alpha: 0.22),
              border: Border.all(color: colorScheme.error.withValues(alpha: 0.18)),
            ),
            child: ListTile(
              leading: isLoggingOut
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: colorScheme.error,
                      ),
                    )
                  : Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text(
                isLoggingOut ? 'Logging Out...' : 'Log Out',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Securely end this session on this device.',
                style: TextStyle(
                  color: colorScheme.onErrorContainer.withValues(alpha: 0.78),
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onTap: actionsDisabled ? null : onLogout,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Delete Account
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FilledButton.icon(
            onPressed: actionsDisabled ? null : onDeleteAccount,
            icon: isDeletingAccount
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever, size: 20),
            label: Text(
              isDeletingAccount ? 'Deleting Account...' : 'Delete Account',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled
            ? colorScheme.primary.withValues(alpha: 0.7)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: enabled ? onTap : null,
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
