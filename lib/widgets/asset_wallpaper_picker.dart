// title=lib/widgets/asset_wallpaper_picker.dart
// Adds the missing `onPicked` callback used by edit_profile_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

class AssetWallpaperPicker extends StatefulWidget {
  const AssetWallpaperPicker({
    super.key,
    required this.onPicked,
    this.includePrefixes = const [
      'assets/images/placeholders/background/',
      'assets/images/', // optional extra bucket
    ],
  });

  final ValueChanged<String> onPicked;
  final List<String> includePrefixes;

  @override
  State<AssetWallpaperPicker> createState() => _AssetWallpaperPickerState();
}

class _AssetWallpaperPickerState extends State<AssetWallpaperPicker> {
  List<String> _assets = const [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final manifest =
          await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> map = json.decode(manifest);
      final items = map.keys
          .where((k) => widget.includePrefixes.any((p) => k.startsWith(p)))
          .toList()
        ..sort();
      setState(() => _assets = items);
    } catch (_) {
      setState(() => _assets = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Choose Background')),
        body: _assets.isEmpty
            ? const Center(child: Text('No wallpapers found'))
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _assets.length,
                itemBuilder: (context, i) {
                  final p = _assets[i];
                  return InkWell(
                    onTap: () {
                      widget.onPicked(p);
                      Navigator.of(context).maybePop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        p,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
