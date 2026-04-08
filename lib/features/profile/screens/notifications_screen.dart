import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _newReviews = true;
  bool _eventReminders = true;
  bool _promotions = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _emailUpdates = prefs.getBool('notif_email') ?? false;
      _newReviews = prefs.getBool('notif_reviews') ?? true;
      _eventReminders = prefs.getBool('notif_events') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? false;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'General',
            children: [
              _buildSwitch(
                context,
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive push notifications on your device',
                value: _pushNotifications,
                onChanged: (v) {
                  setState(() => _pushNotifications = v);
                  _save('notif_push', v);
                },
              ),
              _buildSwitch(
                context,
                icon: Icons.email_outlined,
                title: 'Email Updates',
                subtitle: 'Receive weekly email digests',
                value: _emailUpdates,
                onChanged: (v) {
                  setState(() => _emailUpdates = v);
                  _save('notif_email', v);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: 'Activity',
            children: [
              _buildSwitch(
                context,
                icon: Icons.rate_review_outlined,
                title: 'New Reviews',
                subtitle: 'Notify when someone reviews a place you saved',
                value: _newReviews,
                onChanged: (v) {
                  setState(() => _newReviews = v);
                  _save('notif_reviews', v);
                },
              ),
              _buildSwitch(
                context,
                icon: Icons.event_outlined,
                title: 'Event Reminders',
                subtitle: 'Remind about upcoming saved events',
                value: _eventReminders,
                onChanged: (v) {
                  setState(() => _eventReminders = v);
                  _save('notif_events', v);
                },
              ),
              _buildSwitch(
                context,
                icon: Icons.local_offer_outlined,
                title: 'Promotions',
                subtitle: 'Receive promotional offers and deals',
                value: _promotions,
                onChanged: (v) {
                  setState(() => _promotions = v);
                  _save('notif_promotions', v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(icon, color: colorScheme.primary.withValues(alpha: 0.7)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
