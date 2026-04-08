import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/content_creation_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../listings/providers/listing_providers.dart';
import '../../posts/providers/post_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedCategoryId;
  bool _isSubmitting = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final creationService = ref.read(contentCreationServiceProvider);
      final mediaService = ref.read(mediaServiceProvider);
      final userId = creationService.currentUser.id;

      var imageUrl = '';
      if (_selectedImageBytes != null && _selectedImageName != null) {
        imageUrl = await mediaService.uploadImage(
          userId: userId,
          folder: 'posts',
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
        );
      }

      await creationService.createPost(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId ?? '',
        location: _locationController.text,
        imageUrl: imageUrl,
      );

      ref.invalidate(recentPostsProvider);
      ref.invalidate(homeRecentPostsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post published successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish post: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.primary.withValues(alpha: 0.8)),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Could not load categories: $err'),
        ),
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.16),
                        colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share a local update',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post quick updates, discoveries, and community notes that feel right at home in Pulse.',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration:
                      _inputDecoration(context, 'Title', Icons.title_rounded),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: _inputDecoration(
                    context,
                    'Category',
                    Icons.category_rounded,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _selectedCategoryId = value;
                  }),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                    context,
                    'Location',
                    Icons.location_on_outlined,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    context,
                    'Description',
                    Icons.notes_rounded,
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Description is required'
                          : null,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _selectedImageBytes == null
                        ? 'Add Cover Image'
                        : 'Change Image',
                  ),
                ),
                if (_selectedImageBytes != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(_isSubmitting ? 'Publishing...' : 'Publish Post'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
