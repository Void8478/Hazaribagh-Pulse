import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _avatarUrlController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
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
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(userProfileProvider).value;
      if (user == null) throw Exception('User not found');

      final data = <String, dynamic>{};
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
      if (_avatarUrlController.text.trim() != user.avatarUrl) {
        data['avatar_url'] = _avatarUrlController.text.trim();
      }

      if (data.isNotEmpty) {
        await ref.read(profileRepositoryProvider).updateProfile(user.id, data);
        ref.invalidate(userProfileProvider);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          _populateFields(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.4),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            backgroundImage: _avatarUrlController.text.isNotEmpty
                                ? NetworkImage(_avatarUrlController.text)
                                : null,
                            child: _avatarUrlController.text.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 52,
                                    color: colorScheme.onSurfaceVariant,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.isEmpty) return null;
                      if (username.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _locationController,
                    label: 'Location',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.notes_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: _avatarUrlController,
                    label: 'Avatar URL',
                    icon: Icons.link,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
        prefixIcon: Icon(
          icon,
          color: colorScheme.primary.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }
}
