import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:image_picker/image_picker.dart';

class AddListingPage extends ConsumerStatefulWidget {
  const AddListingPage({super.key});

  @override
  ConsumerState<AddListingPage> createState() => _AddListingPageState();
}

class _AddListingPageState extends ConsumerState<AddListingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Fields
  String _title = '';
  String _subtitle = '';
  double _price = 0.0;
  String _location = '';
  String _condition = 'used';
  String _category = 'part';
  String _description = '';
  List<XFile> _selectedImages = [];

  // Fitment (Optional)
  String? _make;
  String? _model;
  int? _year;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to list an item.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image.')),
      );
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

      final product = Product(
        id: '', // Set by Supabase
        sellerId: user.id,
        title: _title,
        subtitle: _subtitle,
        price: _price,
        imageUrls: uploadedUrls,
        category: _category,
        condition: _condition,
        location: _location,
        isFeatured: false,
        createdAt: DateTime.now(),
        description: _description,
        fitment: (_make != null && _model != null && _year != null)
            ? {
                'make': _make!,
                'model': _model!,
                'year': _year!,
              }
            : null,
      );

      await productService.addProduct(product);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing Published!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('New Listing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Basic Details'),
                    TextFormField(
                      decoration: _inputDecoration('Title (e.g. Toyota Corolla Engine)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _title = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _inputDecoration('Subtitle (e.g. 1.6L VVT-i, Low Mileage)'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _subtitle = v!,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Category'),
                            initialValue: _category,
                            dropdownColor: BoostDriveTheme.surfaceDark,
                            items: const [
                              DropdownMenuItem(value: 'part', child: Text('Part')),
                              DropdownMenuItem(value: 'car', child: Text('Car')),
                              DropdownMenuItem(value: 'rental', child: Text('Rental')),
                            ],
                            onChanged: (v) => setState(() => _category = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Condition'),
                            initialValue: _condition,
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

                    const SizedBox(height: 32),
                    _buildSectionHeader('Pricing & Location'),
                    TextFormField(
                      decoration: _inputDecoration('Price (N\$)').copyWith(prefixText: 'N\$ '),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid Price' : null,
                      onSaved: (v) => _price = double.parse(v!.replaceAll(',', '')),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _inputDecoration('City / Region'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _location = v!,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Vehicle Fitment (Optional)'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: _inputDecoration('Make (e.g. Toyota)'),
                            onSaved: (v) => _make = v?.isEmpty ?? true ? null : v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: _inputDecoration('Year'),
                            keyboardType: TextInputType.number,
                            onSaved: (v) => _year = v?.isEmpty ?? true ? null : int.tryParse(v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _inputDecoration('Model (e.g. Corolla)'),
                      onSaved: (v) => _model = v?.isEmpty ?? true ? null : v,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Detailed Description'),
                    TextFormField(
                      decoration: _inputDecoration('Detailed Item Description (min. 500 chars)')
                          .copyWith(
                            alignLabelWithHint: true,
                            counterText: '${_description.length} / 500 minimum',
                            counterStyle: TextStyle(
                              color: _description.length < 500 ? Colors.orange : Colors.green,
                            ),
                          ),
                      maxLines: null,
                      minLines: 6,
                      keyboardType: TextInputType.multiline,
                      onChanged: (v) => setState(() => _description = v),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Description is required';
                        if (v.length < 500) return 'Description must be at least 500 characters';
                        return null;
                      },
                      onSaved: (v) => _description = v!,
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader('Images'),
                    BoostImagePicker(
                      onChanged: (images) => setState(() => _selectedImages = images),
                      label: 'Vehicle Photos',
                      maxImages: 10,
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoostDriveTheme.primaryColor,
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Publish Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: BoostDriveTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: BoostDriveTheme.textDim),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BoostDriveTheme.primaryColor)),
    );
  }
}
