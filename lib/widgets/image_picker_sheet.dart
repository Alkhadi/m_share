import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'asset_image_grid.dart';

/// Bottom sheet with two tabs:
/// - App Images (grid of bundled assets you list)
/// - My Device (opens gallery via image_picker)
class ImagePickerSheet extends StatefulWidget {
  const ImagePickerSheet({
    super.key,
    required this.title,
    required this.appImages,
    required this.onPicked,
  });

  final String title;
  final List<String> appImages; // e.g. bundled avatars or backgrounds
  final ValueChanged<String> onPicked; // returns asset path or device file path

  @override
  State<ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<ImagePickerSheet>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final x =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 92);
    if (x == null) return;
    // Return a normal file path
    widget.onPicked(File(x.path).path);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    Tab(text: 'App Images'),
                    Tab(text: 'My Device'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 430,
                  child: TabBarView(
                    children: [
                      // App Images
                      SingleChildScrollView(
                        child: AssetImageGrid(
                          assets: widget.appImages,
                          onPick: (a) {
                            widget.onPicked(a);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      // My Device
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 84),
                            const SizedBox(height: 12),
                            const Text('Choose an image from your gallery'),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo),
                              label: const Text('Open Gallery'),
                            ),
                          ],
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
}
