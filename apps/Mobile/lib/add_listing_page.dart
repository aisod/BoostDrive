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

  String _title = '';
  String _subtitle = '';
  double _price = 0.0;
  String _location = '';
  String _condition = 'used';
  String _category = 'part';
  String _description = '';
  List<XFile> _selectedImages = [];

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

      for (final image in _selectedImages) {
        final bytes = await image.readAsBytes();
        final url = await productService.uploadProductImage(bytes, image.name);
        uploadedUrls.add(url);
      }

      final product = Product(
        id: '',
        sellerId: user.id,
        title: _title,
        subtitle: _subtitle,
        price: _price,
        imageUrls: uploadedUrls,
        category: _category,
        condition: _condition,
        location: _location,
        isFeatured: false,
        status: 'pending',
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing Published!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        final palette = DashboardPalette.of(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: palette.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShopCommerceUi.radiusCard)),
            title: Text('Error', style: TextStyle(color: palette.title)),
            content: Text(e.toString(), style: TextStyle(color: palette.body)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: palette.primaryContainer)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: ShopCommerceUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'New Listing',
        onColoredHeader: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: palette.primaryContainer))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        ShopCommerceUi.marginMobile,
                        8,
                        ShopCommerceUi.marginMobile,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BoostImagePicker(
                            useGridLayout: true,
                            onChanged: (images) => setState(() => _selectedImages = images),
                            label: 'Vehicle Photos',
                            maxImages: 10,
                          ),
                          const SizedBox(height: 24),
                          ShopCommerceUi.sectionLabel(palette, 'Basic Details'),
                          ShopCommerceUi.sectionCard(
                            palette: palette,
                            child: Column(
                              children: [
                                _labeledFormField(
                                  palette,
                                  label: 'Listing Title',
                                  hint: 'e.g. Toyota Corolla Engine',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  onSaved: (v) => _title = v!,
                                ),
                                const SizedBox(height: 16),
                                _labeledFormField(
                                  palette,
                                  label: 'Subtitle / Tagline',
                                  hint: 'e.g. 1.6L VVT-i, Low Mileage',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  onSaved: (v) => _subtitle = v!,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: _categoryDropdown(palette)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _conditionDropdown(palette)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShopCommerceUi.sectionLabel(palette, 'Pricing & Location'),
                          ShopCommerceUi.sectionCard(
                            palette: palette,
                            child: Column(
                              children: [
                                _labeledFormField(
                                  palette,
                                  label: 'Price (N\$)',
                                  hint: '0.00',
                                  keyboardType: TextInputType.number,
                                  prefixText: 'N\$ ',
                                  validator: (v) =>
                                      v == null || double.tryParse(v.replaceAll(',', '')) == null
                                          ? 'Invalid Price'
                                          : null,
                                  onSaved: (v) => _price = double.parse(v!.replaceAll(',', '')),
                                ),
                                const SizedBox(height: 16),
                                _labeledFormField(
                                  palette,
                                  label: 'City / Region',
                                  hint: 'Windhoek',
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                  onSaved: (v) => _location = v!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShopCommerceUi.sectionLabel(palette, 'Vehicle Fitment'),
                          ShopCommerceUi.sectionCard(
                            palette: palette,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _labeledFormField(
                                        palette,
                                        label: 'Make',
                                        hint: 'Toyota',
                                        onSaved: (v) => _make = v?.isEmpty ?? true ? null : v,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _labeledFormField(
                                        palette,
                                        label: 'Year',
                                        hint: '2023',
                                        keyboardType: TextInputType.number,
                                        onSaved: (v) => _year = v?.isEmpty ?? true ? null : int.tryParse(v!),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _labeledFormField(
                                        palette,
                                        label: 'Model',
                                        hint: 'Corolla',
                                        onSaved: (v) => _model = v?.isEmpty ?? true ? null : v,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ShopCommerceUi.sectionLabel(palette, 'Detailed Description'),
                          ShopCommerceUi.sectionCard(
                            palette: palette,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  maxLines: 6,
                                  style: TextStyle(color: palette.title, fontSize: 15),
                                  decoration: ShopCommerceUi.formDecoration(
                                    palette,
                                    hint: "Describe your vehicle's features, history, and any special upgrades...",
                                  ),
                                  onChanged: (v) => setState(() => _description = v),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Description is required';
                                    return null;
                                  },
                                  onSaved: (v) => _description = v!,
                                ),
                                const SizedBox(height: 12),
                                ShopCommerceUi.infoHint(
                                  palette,
                                  'Be as detailed as possible to attract more buyers.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ShopCommerceUi.listingStickyFooter(
                    context: context,
                    palette: palette,
                    onPublish: _submit,
                    loading: _isLoading,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _labeledFormField(
    DashboardPalette palette, {
    required String label,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShopCommerceUi.labeledFieldHeader(palette, label),
        TextFormField(
          keyboardType: keyboardType,
          style: TextStyle(color: palette.title, fontSize: 15),
          decoration: ShopCommerceUi.formDecoration(palette, hint: hint, prefixText: prefixText),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _categoryDropdown(DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShopCommerceUi.labeledFieldHeader(palette, 'Category'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          dropdownColor: palette.surfaceContainerLowest,
          style: TextStyle(color: palette.title, fontSize: 15),
          decoration: ShopCommerceUi.formDecoration(palette),
          items: const [
            DropdownMenuItem(value: 'part', child: Text('Part')),
            DropdownMenuItem(value: 'car', child: Text('Car')),
            DropdownMenuItem(value: 'rental', child: Text('Rental')),
          ],
          onChanged: (v) => setState(() => _category = v!),
        ),
      ],
    );
  }

  Widget _conditionDropdown(DashboardPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShopCommerceUi.labeledFieldHeader(palette, 'Condition'),
        DropdownButtonFormField<String>(
          initialValue: _condition,
          dropdownColor: palette.surfaceContainerLowest,
          style: TextStyle(color: palette.title, fontSize: 15),
          decoration: ShopCommerceUi.formDecoration(palette),
          items: const [
            DropdownMenuItem(value: 'new', child: Text('New')),
            DropdownMenuItem(value: 'used', child: Text('Used')),
            DropdownMenuItem(value: 'salvage', child: Text('Salvage')),
          ],
          onChanged: (v) => setState(() => _condition = v!),
        ),
      ],
    );
  }
}
