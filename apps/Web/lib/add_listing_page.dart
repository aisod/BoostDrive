import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddListingPage extends ConsumerStatefulWidget {
  const AddListingPage({super.key});

  @override
  ConsumerState<AddListingPage> createState() => _AddListingPageState();
}

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
    _titleController.dispose();
    _subtitleController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productService = ref.read(productServiceProvider);
      final List<String> uploadedUrls = [];

      // 1. Upload images
      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await productService.uploadProductImage(bytes, image.name);
        uploadedUrls.add(url);
      }
      
      // 2. Parse Price
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: BoostDriveTheme.surfaceDark,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Color(0x22FF6600)),
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
              const Text(
                'Listing Published!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your listing has been successfully listed on BoostDrive.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true); // Return true to signal refresh
                  Navigator.pop(context, true); // Return to home
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Back to Marketplace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumPageLayout(
      appBar: AppBar(
        title: const Text('Add New Listing'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      footer: const AppFooter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.9), // Slightly more transparent for glass effect
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
                side: const BorderSide(color: Color(0x22FF6600)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BoostDriveTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_business, color: BoostDriveTheme.primaryColor),
                          ),
                          const SizedBox(width: 20),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Publish Your Listing',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Join Namibia\'s fastest growing marketplace.',
                                  style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(labelText: 'Category'),
                              dropdownColor: BoostDriveTheme.surfaceDark,
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
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: _condition,
                              decoration: const InputDecoration(labelText: 'Condition'),
                              dropdownColor: BoostDriveTheme.surfaceDark,
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
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Listing Title',
                          hintText: 'e.g., 2024 Toyota Hilux GD-6',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(
                          labelText: 'Subtitle / Key Features',
                          hintText: 'e.g., Double Cab 4x4, Blue, 12,000km',
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter a subtitle' : null,
                      ),
                      
                      const SizedBox(height: 48),
                      _buildSectionTitle('Pricing & Location'),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                prefixText: 'N\$ ',
                              ),
                              validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'City / Region',
                                hintText: 'e.g., Windhoek',
                              ),
                              validator: (v) => v!.isEmpty ? 'Enter a location' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: null,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Detailed Description',
                          hintText: 'Provide a comprehensive description of your item...',
                          alignLabelWithHint: true,
                        ),
                        onChanged: (v) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Description is required';
                          return null;
                        },
                      ),

                      const SizedBox(height: 48),
                      _buildSectionTitle('Media Assets'),
                      const SizedBox(height: 24),
                      BoostImagePicker(
                        onChanged: (images) => setState(() => _selectedImages = images),
                        label: 'Vehicle Photos',
                        maxImages: 10,
                      ),

                      const SizedBox(height: 64),

                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BoostDriveTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Publish Your Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: BoostDriveTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(width: 40, height: 2, color: BoostDriveTheme.primaryColor),
      ],
    );
  }
}
