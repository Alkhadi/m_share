import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Reads AssetManifest.json to list assets dynamically by prefix.
class AssetImageService {
  static Future<List<String>> _listByPrefixes(List<String> prefixes) async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestJson);
    final keys = manifest.keys
        .where((k) => prefixes.any((p) => k.startsWith(p)))
        .toList()
      ..sort();
    return keys;
  }

  /// All backgrounds you can use as wallpapers (both placeholders and images/)
  static Future<List<String>> listBackgrounds() => _listByPrefixes(
      const ['assets/placeholders/background/', 'assets/images/']);

  /// All profile placeholders in the app bundle.
  static Future<List<String>> listProfilePlaceholders() =>
      _listByPrefixes(const ['assets/placeholders/profile/']);

  /// Only the "parlour_next_door_*" series.
  static Future<List<String>> listParlourWallpapers() => _listByPrefixes(
      const ['assets/placeholders/background/parlour_next_door_']);
}
