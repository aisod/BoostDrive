import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditListingPage extends ConsumerStatefulWidget {
  final Product product;
  const EditListingPage({super.key, required this.product});

  @override
  ConsumerState<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends ConsumerState<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _imageUrlsController;
  late TextEditingController _descriptionController;
  
  late String _category;
  late String _condition;
  bool _isLoading = false;
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _subtitleController = TextEditingController(text: widget.product.subtitle);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _locationController = TextEditingController(text: widget.product.location);
    _imageUrlsController = TextEditingController();
    _category = widget.product.category;
    _condition = widget.product.condition;
    _descriptionController = TextEditingController(text: widget.product.description);
    _existingImageUrls = List.from(widget.product.imageUrls);
  }

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
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final productService = ref.read(productServiceProvider);
      final List<String> uploadedUrls = List.from(_existingImageUrls);

      // 1. Upload new images if any
      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await productService.uploadProductImage(bytes, image.name);
        uploadedUrls.add(url);
      }
      
      if (uploadedUrls.isEmpty) {
        throw Exception('Please have at least one image.');
      }

      // 2. Parse Price
      final priceString = _priceController.text.replaceAll(',', '');
      final price = double.parse(priceString);

      final updatedProduct = widget.product.copyWith(
        title: _titleController.text,
        subtitle: _subtitleController.text,
        price: price,
        imageUrls: uploadedUrls,
        category: _category,
        location: _locationController.text,
        condition: _condition,
        description: _descriptionController.text,
      );

      await productService.updateProduct(updatedProduct);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog(updatedProduct);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(Product updatedProduct) {
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
                'Listing Updated!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your changes have been successfully saved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, updatedProduct); // Return to detail page with updated product
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Back to Listing'),
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
        title: const Text('Edit Listing'),
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
              color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.9),
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
                      const Text(
                        'Edit Your Listing',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                        decoration: const InputDecoration(labelText: 'Listing Title'),
                        validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _subtitleController,
                        decoration: const InputDecoration(labelText: 'Subtitle / Key Features'),
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
                              decoration: const InputDecoration(labelText: 'City / Region'),
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
                      // Existing images
                      if (_existingImageUrls.isNotEmpty) ...[
                        const Text('Existing Photos', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 14)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length,
                            itemBuilder: (context, index) => Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(_existingImageUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _existingImageUrls.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      BoostImagePicker(
                        onChanged: (images) => setState(() => _selectedImages = images),
                        label: 'Add More Photos',
                        maxImages: 10 - _existingImageUrls.length,
                      ),

                      const SizedBox(height: 64),

                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BoostDriveTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
