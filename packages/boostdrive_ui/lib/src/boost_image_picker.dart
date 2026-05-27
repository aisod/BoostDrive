import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dashboard_palette.dart';
import 'shop_commerce_ui.dart';

class BoostImagePicker extends StatefulWidget {
  final List<XFile> initialImages;
  final Function(List<XFile> images) onChanged;
  final String label;
  final int maxImages;
  final bool useGridLayout;

  const BoostImagePicker({
    super.key,
    this.initialImages = const [],
    required this.onChanged,
    this.label = 'Photos',
    this.maxImages = 10,
    this.useGridLayout = false,
  });

  @override
  State<BoostImagePicker> createState() => _BoostImagePickerState();
}

class _BoostImagePickerState extends State<BoostImagePicker> {
  late List<XFile> _images;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> result = await _picker.pickMultiImage();
      if (result.isNotEmpty) {
        setState(() {
          _images.addAll(result);
          if (_images.length > widget.maxImages) {
            _images = _images.sublist(0, widget.maxImages);
          }
        });
        widget.onChanged(_images);
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);

    if (widget.useGridLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShopCommerceUi.sectionLabel(palette, widget.label),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossCount = 4;
              const spacing = 8.0;
              final cell = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
              final slots = <Widget>[];
              for (var i = 0; i < _images.length; i++) {
                slots.add(_gridImageCell(palette, i, cell));
              }
              if (_images.length < widget.maxImages) {
                slots.add(_gridAddCell(palette, cell));
              }
              return Wrap(spacing: spacing, runSpacing: spacing, children: slots);
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: palette.secondary,
              ),
            ),
            Text(
              '${_images.length} / ${widget.maxImages}',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                if (_images.length >= widget.maxImages) return const SizedBox.shrink();
                return _buildAddButton(palette);
              }
              return _buildImageCard(palette, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _gridAddCell(DashboardPalette palette, double size) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(ShopCommerceUi.radiusControl),
          border: Border.all(
            color: palette.outlineVariant.withValues(alpha: 0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: palette.primaryContainer, size: 28),
            const SizedBox(height: 4),
            Text(
              'ADD',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: palette.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridImageCell(DashboardPalette palette, int index, double size) {
    final file = _images[index];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ShopCommerceUi.radiusControl),
            child: _imagePreview(file, size, size),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(DashboardPalette palette) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(ShopCommerceUi.radiusControl),
          border: Border.all(color: palette.primaryContainer.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: palette.primaryContainer, size: 32),
            const SizedBox(height: 8),
            Text('Add Photo', style: TextStyle(color: palette.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(DashboardPalette palette, int index) {
    final file = _images[index];
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ShopCommerceUi.radiusControl),
            child: _imagePreview(file, 120, 120),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview(XFile file, double width, double height) {
    if (kIsWeb) {
      return Image.network(file.path, width: width, height: height, fit: BoxFit.cover);
    }
    return Image.file(File(file.path), width: width, height: height, fit: BoxFit.cover);
  }
}
