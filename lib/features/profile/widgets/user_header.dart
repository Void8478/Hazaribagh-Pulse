import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/user_model.dart';

class UserHeader extends StatelessWidget {
  final UserModel user;
  final int? reviewsCountOverride;
  final int? savedCountOverride;
  final int? photosCountOverride;

  const UserHeader({
    super.key,
    required this.user,
    this.reviewsCountOverride,
    this.savedCountOverride,
    this.photosCountOverride,
  });

  String _avatarUrlWithVersion() {
    if (user.avatarUrl.isEmpty) return user.avatarUrl;

    final uri = Uri.tryParse(user.avatarUrl);
    if (uri == null) return user.avatarUrl;

    final version = user.updatedAt?.millisecondsSinceEpoch.toString();
    if (version == null || version.isEmpty) return user.avatarUrl;

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'v': version,
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = _avatarUrlWithVersion();
    final reviewsCount = reviewsCountOverride ?? user.reviewsCount;
    final savedCount = savedCountOverride ?? user.savedPlaceIds.length;
    final photosCount = photosCountOverride ?? user.photosCount;
    final usernameLabel = user.username.isNotEmpty ? '@${user.username}' : '';
    final secondaryText = user.location.isNotEmpty
        ? user.location
        : usernameLabel;
    final joinedLabel = user.createdAt != null
        ? user.createdAt!.year.toString()
        : '--';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.12),
                  colorScheme.surface,
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.surface,
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with gold ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  key: ValueKey('${user.avatarUrl}-${user.updatedAt?.millisecondsSinceEpoch ?? 0}'),
                  radius: 42,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? ResizeImage.resizeIfNeeded(
                          240,
                          240,
                          NetworkImage(avatarUrl),
                        )
                      : null,
                  child: user.avatarUrl.isEmpty
                      ? Icon(Icons.person, size: 42, color: colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryText,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (usernameLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          usernameLabel,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Edit button
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  child: Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
                ),
                onPressed: () => context.push('/edit-profile'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCol(context, reviewsCount.toString(), 'Reviews'),
                _buildDivider(context),
                _buildStatCol(context, savedCount.toString(), 'Saved'),
                _buildDivider(context),
                _buildStatCol(context, photosCount.toString(), 'Photos'),
                _buildDivider(context),
                _buildStatCol(context, joinedLabel, 'Joined'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(BuildContext context, String value, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}
