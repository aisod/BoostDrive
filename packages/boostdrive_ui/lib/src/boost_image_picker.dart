import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'theme.dart';

class BoostImagePicker extends StatefulWidget {
  final List<XFile> initialImages;
  final Function(List<XFile> images) onChanged;
  final String label;
  final int maxImages;

  const BoostImagePicker({
    super.key,
    this.initialImages = const [],
    required this.onChanged,
    this.label = 'Photos',
    this.maxImages = 10,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: BoostDriveTheme.primaryColor,
              ),
            ),
            Text(
              '${_images.length} / ${widget.maxImages}',
              style: const TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
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
                return _buildAddButton();
              }
              return _buildImageCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: BoostDriveTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: BoostDriveTheme.primaryColor, size: 32),
            SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final file = _images[index];
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.network(
                    file.path,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    File(file.path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
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
}
