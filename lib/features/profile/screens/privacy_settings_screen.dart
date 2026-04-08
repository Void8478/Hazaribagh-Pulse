import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profilePublic = true;
  bool _showSavedPlaces = false;
  bool _showReviews = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profilePublic = prefs.getBool('privacy_public') ?? true;
      _showSavedPlaces = prefs.getBool('privacy_saved') ?? false;
      _showReviews = prefs.getBool('privacy_reviews') ?? true;
      _loaded = true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                    'Profile Visibility',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.visibility_outlined, color: colorScheme.primary.withValues(alpha: 0.7)),
                  title: const Text('Public Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Others can see your name and trust level',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  value: _profilePublic,
                  onChanged: (v) {
                    setState(() => _profilePublic = v);
                    _save('privacy_public', v);
                  },
                  activeThumbColor: colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.bookmark_outline, color: colorScheme.primary.withValues(alpha: 0.7)),
                  title: const Text('Show Saved Places', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Make your saved places visible to others',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  value: _showSavedPlaces,
                  onChanged: (v) {
                    setState(() => _showSavedPlaces = v);
                    _save('privacy_saved', v);
                  },
                  activeThumbColor: colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
                SwitchListTile(
                  secondary: Icon(Icons.rate_review_outlined, color: colorScheme.primary.withValues(alpha: 0.7)),
                  title: const Text('Show Reviews', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Make your reviews visible on your profile',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  value: _showReviews,
                  onChanged: (v) {
                    setState(() => _showReviews = v);
                    _save('privacy_reviews', v);
                  },
                  activeThumbColor: colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'These settings control how your activity is displayed to other users. Changes take effect immediately.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
