import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final faqs = [
      {
        'q': 'How do I save a place?',
        'a': 'Tap the bookmark icon on any listing card or on the listing detail page. Saved places appear in your Profile under "Saved Places".',
      },
      {
        'q': 'How do I write a review?',
        'a': 'Open any listing and scroll to the Reviews section. Tap "Write a Review" to share your experience with ratings, pros, cons, and photos.',
      },
      {
        'q': 'What is Trust Level?',
        'a': 'Your Trust Level reflects your community contributions — reviews, photos, and engagement. Higher levels unlock special badges and features.',
      },
      {
        'q': 'How do I change my profile information?',
        'a': 'Go to Profile → Edit Profile. You can update your name, phone number, and avatar URL. Email cannot be changed as it is linked to your account.',
      },
      {
        'q': 'How do I delete my account?',
        'a': 'Go to Profile → scroll to bottom → tap "Delete Account". You\'ll need to type DELETE to confirm. This action is permanent and cannot be undone.',
      },
      {
        'q': 'Is Hazaribagh Pulse free to use?',
        'a': 'Yes! Hazaribagh Pulse is completely free for users. We may offer premium listings for businesses in the future.',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.15),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.help_outline, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'How can we help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Browse frequently asked questions below',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FAQ List
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionPanelList.radio(
              elevation: 0,
              expandedHeaderPadding: EdgeInsets.zero,
              children: faqs.asMap().entries.map((entry) {
                return ExpansionPanelRadio(
                  value: entry.key,
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      leading: Icon(
                        Icons.quiz_outlined,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      title: Text(
                        entry.value['q']!,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                    child: Text(
                      entry.value['a']!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Contact
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.email_outlined, color: colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Still need help?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'support@hazaribaghpulse.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
