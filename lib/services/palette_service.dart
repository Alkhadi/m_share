// title=lib/services/palette_service.dart
import 'package:flutter/material.dart';

/// Lightweight "seeded" scheme. If [seed] is null, fall back to indigo.
class PaletteService {
  static ColorScheme schemeFromSeed(
      {Color? seed, Brightness brightness = Brightness.light}) {
    final base = seed ?? const Color(0xFF3F51B5); // Indigo
    // Use Flutter's built‑in ColorScheme.fromSeed.  The imported
    // material_color_utilities CorePalette is unused and therefore
    // omitted to avoid extra dependencies.
    return brightness == Brightness.dark
        ? ColorScheme.fromSeed(seedColor: base, brightness: Brightness.dark)
        : ColorScheme.fromSeed(seedColor: base, brightness: Brightness.light);
  }
}
