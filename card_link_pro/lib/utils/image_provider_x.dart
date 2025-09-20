import 'package:flutter/material.dart';

/// Load an [ImageProvider] from either an asset path or network URL.
///
/// If [path] begins with `http://` or `https://`, a [NetworkImage] is
/// returned.  Otherwise, an [AssetImage] is used.  This helper makes it
/// easier to handle user‑provided files or bundled assets uniformly.
ImageProvider loadImageProvider(String path) {
  final trimmed = path.trim();
  if (trimmed.startsWith(RegExp(r'https?://'))) {
    return NetworkImage(trimmed);
  }
  return AssetImage(trimmed);
}