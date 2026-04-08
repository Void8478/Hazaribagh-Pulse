import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/content_creation_providers.dart';
import '../../events/providers/event_providers.dart';
import '../../home/providers/home_providers.dart';
import '../../listings/providers/listing_providers.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizerController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isFree = true;
  bool _isSubmitting = false;
  DateTime? _selectedDate;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizerController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = file.name;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _selectedDate ?? now,
    );
    if (date == null) return;

    if (!mounted) return;
    setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    if (!mounted) return;
    setState(() {
      _timeController.text = time.format(context);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event date is required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final creationService = ref.read(contentCreationServiceProvider);
      final mediaService = ref.read(mediaServiceProvider);
      final userId = creationService.currentUser.id;

      var imageUrl = '';
      if (_selectedImageBytes != null && _selectedImageName != null) {
        imageUrl = await mediaService.uploadImage(
          userId: userId,
          folder: 'events',
          bytes: _selectedImageBytes!,
          fileName: _selectedImageName!,
        );
      }

      await creationService.createEvent(
        title: _titleController.text,
        description: _descriptionController.text,
        categoryId: _selectedCategoryId ?? '',
        categoryName: _selectedCategoryName ?? '',
        location: _locationController.text,
        date: _selectedDate!,
        time: _timeController.text,
        imageUrl: imageUrl,
        organizer: _organizerController.text,
        address: _addressController.text,
        isFree: _isFree,
        price: _priceController.text,
      );

      ref.invalidate(allEventsProvider);
      ref.invalidate(homeUpcomingEventsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event created successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create event: $e'),
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
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
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
                        colorScheme.tertiary.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a local event',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publish events that the community can discover instantly across Pulse.',
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
                  decoration: _inputDecoration(
                    context,
                    'Event Title',
                    Icons.celebration_outlined,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Event title is required'
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
                  onChanged: (value) {
                    final selected = categories
                        .where((category) => category.id == value)
                        .toList();
                    setState(() {
                      _selectedCategoryId = value;
                      _selectedCategoryName =
                          selected.isNotEmpty ? selected.first.name : null;
                    });
                  },
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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Location is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration:
                      _inputDecoration(context, 'Address', Icons.map_outlined),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _organizerController,
                  decoration: _inputDecoration(
                    context,
                    'Organizer',
                    Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: _inputDecoration(
                    context,
                    'Description',
                    Icons.notes_rounded,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _selectedDate == null
                              ? 'Pick Date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          _timeController.text.isEmpty
                              ? 'Pick Time'
                              : _timeController.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _isFree,
                  onChanged: (value) => setState(() => _isFree = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free Event'),
                ),
                if (!_isFree) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration(
                      context,
                      'Ticket Price',
                      Icons.payments_outlined,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _selectedImageBytes == null
                        ? 'Add Event Image'
                        : 'Change Image',
                  ),
                ),
                if (_selectedImageBytes != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _selectedImageBytes!,
                      height: 190,
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
                        : const Icon(Icons.event_available_outlined),
                    label:
                        Text(_isSubmitting ? 'Publishing...' : 'Publish Event'),
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
