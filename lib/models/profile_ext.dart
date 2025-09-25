// lib/models/profile_ext.dart
// Adds compatibility getters so code can ask for bankName/iban/reference
// even if your core Profile model doesn't define them yet.

import 'profile.dart';

extension ProfileX on Profile {
  /// Optional display bank name (defaults empty until you add it to Profile).
  String get bankName => '';

  /// Optional IBAN (defaults empty until you add it to Profile).
  String get iban => '';

  /// Optional payment reference (defaults 'M SHARE' for now).
  String get reference => 'M SHARE';

  /// Best‑effort slug to use as a canonical id when you don't yet have one
  /// from the Worker (purely cosmetic).
  String get canonicalId =>
      fullName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
