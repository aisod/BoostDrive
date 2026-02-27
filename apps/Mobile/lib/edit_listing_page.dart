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

      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await productService.uploadProductImage(bytes, image.name);
        uploadedUrls.add(url);
      }
      
      if (uploadedUrls.isEmpty) throw Exception('Please have at least one image.');

      final price = double.parse(_priceController.text.replaceAll(',', ''));

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
        Navigator.pop(context, updatedProduct);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtitle'),
                validator: (v) => v!.isEmpty ? 'Enter a subtitle' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (N\$)', prefixText: 'N\$ '),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a valid price' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                validator: (v) => v!.isEmpty ? 'Enter a location' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Detailed Description',
                  alignLabelWithHint: true,
                  counterText: '${_descriptionController.text.length} / 500 minimum',
                  counterStyle: TextStyle(
                    color: _descriptionController.text.length < 500 ? Colors.orange : Colors.green,
                  ),
                ),
                onChanged: (v) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 500) return 'Description must be at least 500 characters';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_existingImageUrls.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_existingImageUrls[index], width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _existingImageUrls.removeAt(index)),
                              child: Container(color: Colors.black54, child: const Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              BoostImagePicker(
                onChanged: (images) => setState(() => _selectedImages = images),
                label: 'Add More Photos',
                maxImages: 10 - _existingImageUrls.length,
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoostDriveTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
