import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_model.dart';
import '../../content/providers/content_creation_providers.dart';
import '../providers/profile_providers.dart';
import '../services/supabase_profile_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _emailController;

  bool _isSaving = false;
  bool _isPickingAvatar = false;
  bool _initialized = false;
  bool _showSlowLoadHint = false;
  String? _inlineMessage;
  bool _inlineMessageIsError = false;
  Uint8List? _selectedAvatarBytes;
  String? _selectedAvatarName;
  Timer? _slowLoadTimer;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _avatarUrlController = TextEditingController();
    _emailController = TextEditingController();
    _slowLoadTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSlowLoadHint = true);
    });
  }

  @override
  void dispose() {
    _slowLoadTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _avatarUrlController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    if (_initialized) return;

    _nameController.text = user.name;
    _usernameController.text = user.username;
    _bioController.text = user.bio;
    _locationController.text = user.location;
    _avatarUrlController.text = user.avatarUrl;
    _emailController.text = user.email;
    _initialized = true;
    _slowLoadTimer?.cancel();
  }

  void _setInlineMessage(String? message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageIsError = isError;
    });
  }

  Future<void> _pickAvatar() async {
    setState(() {
      _isPickingAvatar = true;
      _inlineMessage = null;
    });

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedAvatarBytes = bytes;
        _selectedAvatarName = file.name;
      });
      _setInlineMessage(
        'New avatar selected. It will upload when you save your profile.',
      );
    } catch (error) {
      _setInlineMessage(
        formatProfileServiceError(
          error,
          fallbackMessage: 'Failed to choose an avatar image.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingAvatar = false);
      }
    }
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Full name is required.';
    }
    if (text.length < 2) {
      return 'Full name must be at least 2 characters.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) {
      return null;
    }
    final usernamePattern = RegExp(r'^[a-zA-Z0-9._]{3,24}$');
    if (!usernamePattern.hasMatch(username)) {
      return 'Use 3-24 letters, numbers, dots, or underscores.';
    }
    return null;
  }

  String? _validateBio(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 180) {
      return 'Bio must stay under 180 characters.';
    }
    return null;
  }

  String? _validateLocation(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 60) {
      return 'Location must stay under 60 characters.';
    }
    return null;
  }

  String? _validateAvatarUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Enter a valid image URL or use Upload Avatar.';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(userProfileProvider).value;
    if (user == null) {
      _setInlineMessage('Your profile is unavailable. Please reload and try again.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
      _inlineMessage = null;
    });

    try {
      final repository = ref.read(profileRepositoryProvider);
      final mediaService = ref.read(mediaServiceProvider);
      final data = <String, dynamic>{};
      var avatarUrl = _avatarUrlController.text.trim();

      if (_selectedAvatarBytes != null && _selectedAvatarName != null) {
        avatarUrl = await mediaService.uploadImage(
          userId: user.id,
          folder: 'avatars',
          bytes: _selectedAvatarBytes!,
          fileName: _selectedAvatarName!,
        );
      }

      if (_nameController.text.trim() != user.name) {
        data['full_name'] = _nameController.text.trim();
      }
      if (_usernameController.text.trim() != user.username) {
        data['username'] = _usernameController.text.trim();
      }
      if (_bioController.text.trim() != user.bio) {
        data['bio'] = _bioController.text.trim();
      }
      if (_locationController.text.trim() != user.location) {
        data['location'] = _locationController.text.trim();
      }
      if (avatarUrl != user.avatarUrl) {
        data['avatar_url'] = avatarUrl;
      }

      if (data.isEmpty) {
        _setInlineMessage('Nothing changed yet. Update a field to save.');
        return;
      }

      await repository.updateProfile(user.id, data);

      ref.invalidate(userProfileProvider);
      _selectedAvatarBytes = null;
      _selectedAvatarName = null;
      _avatarUrlController.text = avatarUrl;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      context.pop();
    } catch (error) {
      _setInlineMessage(
        formatProfileServiceError(
          error,
          fallbackMessage: _selectedAvatarBytes != null
              ? 'Failed to upload avatar and save profile.'
              : 'Failed to save your profile.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: userAsync.when(
        loading: () => _EditProfileLoadingState(
          showSlowLoadHint: _showSlowLoadHint,
        ),
        error: (err, _) => _EditProfileErrorState(
          message: '$err',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return _EditProfileErrorState(
              message: 'Your profile is not available right now.',
              onRetry: () => ref.invalidate(userProfileProvider),
            );
          }

          _populateFields(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.14),
                          colorScheme.secondary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        _AvatarPreview(
                          imageBytes: _selectedAvatarBytes,
                          imageUrl: _avatarUrlController.text.trim(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keep your public identity polished',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Update how people see you across posts, reviews, bookmarks, and profile surfaces.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed:
                                  _isSaving || _isPickingAvatar ? null : _pickAvatar,
                              icon: _isPickingAvatar
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_rounded),
                              label: Text(
                                _isPickingAvatar
                                    ? 'Choosing...'
                                    : 'Upload Avatar',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isSaving || _isPickingAvatar
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedAvatarBytes = null;
                                        _selectedAvatarName = null;
                                        _avatarUrlController.clear();
                                      });
                                      _setInlineMessage(
                                        'Avatar cleared. Save to apply this change.',
                                      );
                                    },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove Avatar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_inlineMessage != null) ...[
                    const SizedBox(height: 16),
                    _InlineStatusCard(
                      message: _inlineMessage!,
                      isError: _inlineMessageIsError,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Profile details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These details are visible across your account and content.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _nameController,
                    label: 'Full Name',
                    helper: 'Shown on your profile and public activity.',
                    icon: Icons.person_outline_rounded,
                    validator: _validateName,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _usernameController,
                    label: 'Username',
                    helper: 'Optional. Use letters, numbers, dots, or underscores.',
                    icon: Icons.alternate_email_rounded,
                    validator: _validateUsername,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _locationController,
                    label: 'Location',
                    helper: 'Optional. Helps personalize your profile.',
                    icon: Icons.location_on_outlined,
                    validator: _validateLocation,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _bioController,
                    label: 'Bio',
                    helper: 'Optional. Keep it short and personal.',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                    validator: _validateBio,
                    enabled: !_isSaving,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _avatarUrlController,
                    label: 'Avatar URL',
                    helper: 'Optional fallback if you prefer a hosted image URL.',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    validator: _validateAvatarUrl,
                    enabled: !_isSaving,
                    onChanged: (_) => setState(() {
                      _selectedAvatarBytes = null;
                      _selectedAvatarName = null;
                    }),
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    helper: 'Managed by authentication and not editable here.',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.28,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_done_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isSaving
                                ? 'Saving your profile securely. Please keep this screen open.'
                                : 'Changes save directly to your account profile. Slow network connections may take a few extra seconds.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving || _isPickingAvatar ? null : _saveProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_isSaving ? 'Saving Changes...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String helper,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: TextStyle(
        color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(
          icon,
          color: colorScheme.primary.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageBytes,
    required this.imageUrl,
  });

  final Uint8List? imageBytes;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNetworkImage = imageUrl.isNotEmpty && imageBytes == null;

    return Container(
      width: 118,
      height: 118,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.9),
            colorScheme.secondary.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: colorScheme.surface,
          child: imageBytes != null
              ? Image.memory(imageBytes!, fit: BoxFit.cover)
              : hasNetworkImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _AvatarFallback(colorScheme: colorScheme);
                      },
                    )
                  : _AvatarFallback(colorScheme: colorScheme),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 54,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError
            ? colorScheme.errorContainer.withValues(alpha: 0.9)
            : colorScheme.primaryContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: isError
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError
                    ? colorScheme.onErrorContainer
                    : colorScheme.onPrimaryContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileLoadingState extends StatelessWidget {
  const _EditProfileLoadingState({required this.showSlowLoadHint});

  final bool showSlowLoadHint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              'Loading your profile settings...',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showSlowLoadHint) ...[
              const SizedBox(height: 10),
              Text(
                'This is taking a little longer than usual. We are still trying securely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditProfileErrorState extends StatelessWidget {
  const _EditProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'We could not load your settings.',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
