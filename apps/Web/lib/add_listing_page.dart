import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boost_drive_web/public_page_frame.dart';
import 'package:boost_drive_web/public_page_widgets.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:image_picker/image_picker.dart';

/// Page for creating and publishing a new marketplace listing.
class AddListingPage extends ConsumerStatefulWidget {
  const AddListingPage({super.key});

  @override
  ConsumerState<AddListingPage> createState() => _AddListingPageState();
}

/// Holds form state, selected media, and submit flow for new listing.
class _AddListingPageState extends ConsumerState<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlsController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _category = 'car';
  String _condition = 'new';
  bool _isLoading = false;
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    // Dispose all text controllers to free memory.
    _titleController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    // Stop submit if required form fields are invalid.
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to list an item.')),
        );
      }
      return;
    }

    if (_selectedImages.isEmpty) {
      // Require at least one image before publishing.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Product service handles uploads and DB insert.
      final productService = ref.read(productServiceProvider);
      final List<String> uploadedUrls = [];

      // 1) Upload selected images and collect resulting URLs.
      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await productService.uploadProductImage(bytes, image.name);
        uploadedUrls.add(url);
      }
      
      // 2) Parse price text into numeric value.
      final priceString = _priceController.text.replaceAll(',', '');
      final price = double.parse(priceString);

      final product = Product(
        id: '', // Will be set by Supabase
        sellerId: user.id,
        title: _titleController.text,
        subtitle: _subtitleController.text,
        price: price,
        imageUrls: uploadedUrls,
        category: _category,
        location: _locationController.text,
        isFeatured: true,
        condition: _condition,
        status: 'pending',
        createdAt: DateTime.now(),
        description: _descriptionController.text,
      );

      await productService.addProduct(product);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Failed'),
            content: Text('Error: $e'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    final palette = PublicPagePalette.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: palette.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: palette.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 32),
              Text(
                'Listing Published!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: palette.titleColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Your listing has been successfully listed on BoostDrive.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.bodyColor, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              PublicPrimaryButton(
                label: 'Back to Marketplace',
                expanded: true,
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label, {String? hint, String? prefix}) {
    final palette = PublicPagePalette.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      filled: true,
      fillColor: palette.fieldBackground,
      labelStyle: TextStyle(color: palette.mutedColor, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = PublicPagePalette.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return PublicPageFrame(
      activeRoute: '/sell-your-car',
      child: ColoredBox(
        color: palette.pageBackground,
        child: PublicPageContainer(
          maxWidth: 800,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: palette.titleColor),
                    ),
                    Text(
                      'Add New Listing',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: palette.titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.06),
                          border: Border(bottom: BorderSide(color: palette.borderColor)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: palette.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.add_business, color: palette.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Publish Your Listing',
                                    style: TextStyle(
                                      fontSize: isMobile ? 24 : 28,
                                      fontWeight: FontWeight.w800,
                                      color: palette.titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Join Namibia\'s fastest growing marketplace.',
                                    style: TextStyle(color: palette.bodyColor, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(context, 'Basic Information'),
                              const SizedBox(height: 20),
                              isMobile
                                  ? Column(
                                      children: [
                                        DropdownButtonFormField<String>(
                                          initialValue: _category,
                                          decoration: _fieldDecoration(context, 'Category'),
                                          dropdownColor: palette.cardBackground,
                                          items: const [
                                            DropdownMenuItem(value: 'car', child: Text('Car for Sale')),
                                            DropdownMenuItem(value: 'part', child: Text('Spare Part')),
                                            DropdownMenuItem(value: 'rental', child: Text('Vehicle for Rent')),
                                          ],
                                          onChanged: (v) => setState(() => _category = v!),
                                        ),
                                        const SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          initialValue: _condition,
                                          decoration: _fieldDecoration(context, 'Condition'),
                                          dropdownColor: palette.cardBackground,
                                          items: const [
                                            DropdownMenuItem(value: 'new', child: Text('New')),
                                            DropdownMenuItem(value: 'used', child: Text('Used')),
                                            DropdownMenuItem(value: 'salvage', child: Text('Salvage')),
                                          ],
                                          onChanged: (v) => setState(() => _condition = v!),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _category,
                                            decoration: _fieldDecoration(context, 'Category'),
                                            dropdownColor: palette.cardBackground,
                                            items: const [
                                              DropdownMenuItem(value: 'car', child: Text('Car for Sale')),
                                              DropdownMenuItem(value: 'part', child: Text('Spare Part')),
                                              DropdownMenuItem(value: 'rental', child: Text('Vehicle for Rent')),
                                            ],
                                            onChanged: (v) => setState(() => _category = v!),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _condition,
                                            decoration: _fieldDecoration(context, 'Condition'),
                                            dropdownColor: palette.cardBackground,
                                            items: const [
                                              DropdownMenuItem(value: 'new', child: Text('New')),
                                              DropdownMenuItem(value: 'used', child: Text('Used')),
                                              DropdownMenuItem(value: 'salvage', child: Text('Salvage')),
                                            ],
                                            onChanged: (v) => setState(() => _condition = v!),
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _titleController,
                                decoration: _fieldDecoration(
                                  context,
                                  'Listing Title',
                                  hint: 'e.g., 2024 Toyota Hilux GD-6',
                                ),
                                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _subtitleController,
                                decoration: _fieldDecoration(
                                  context,
                                  'Subtitle / Key Features',
                                  hint: 'e.g., Double Cab 4x4, Blue, 12,000km',
                                ),
                                validator: (v) => v!.isEmpty ? 'Enter a subtitle' : null,
                              ),
                              const SizedBox(height: 36),
                              _buildSectionTitle(context, 'Pricing & Location'),
                              const SizedBox(height: 20),
                              isMobile
                                  ? Column(
                                      children: [
                                        TextFormField(
                                          controller: _priceController,
                                          keyboardType: TextInputType.number,
                                          decoration: _fieldDecoration(context, 'Price', prefix: 'N\$ '),
                                          validator: (v) =>
                                              double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _locationController,
                                          decoration: _fieldDecoration(
                                            context,
                                            'City / Region',
                                            hint: 'e.g., Windhoek',
                                          ),
                                          validator: (v) => v!.isEmpty ? 'Enter a location' : null,
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _priceController,
                                            keyboardType: TextInputType.number,
                                            decoration: _fieldDecoration(context, 'Price', prefix: 'N\$ '),
                                            validator: (v) =>
                                                double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _locationController,
                                            decoration: _fieldDecoration(
                                              context,
                                              'City / Region',
                                              hint: 'e.g., Windhoek',
                                            ),
                                            validator: (v) => v!.isEmpty ? 'Enter a location' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: null,
                                minLines: 8,
                                keyboardType: TextInputType.multiline,
                                decoration: _fieldDecoration(
                                  context,
                                  'Detailed Description',
                                  hint: 'Provide a comprehensive description of your item...',
                                ).copyWith(alignLabelWithHint: true),
                                onChanged: (v) => setState(() {}),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Description is required';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 36),
                              _buildSectionTitle(context, 'Media Assets'),
                              const SizedBox(height: 20),
                              BoostImagePicker(
                                onChanged: (images) => setState(() => _selectedImages = images),
                                label: 'Vehicle Photos',
                                maxImages: 10,
                              ),
                              const SizedBox(height: 40),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: palette.primary,
                                    foregroundColor: palette.onPrimaryContainer,
                                    disabledBackgroundColor: palette.primary.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Publish Your Listing',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final palette = PublicPagePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: palette.primary,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 40, height: 2, color: palette.primary),
      ],
    );
  }
}
