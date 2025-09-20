import 'dart:convert';

import 'package:flutter/material.dart';

/// Canonical profile model used across the app.
class Profile {
  String fullName;
  String role;
  String address;
  String phone;
  String email;
  String website;
  String wellbeingLink;

  String bankSortCode;
  String bankAccountNumber;

  // Optional visuals
  String? avatarPath;
  String? backgroundPath;
  Color? backgroundColor;

  // Optional socials (wide coverage)
  String? linkedin;
  String? instagram;
  String? facebook;
  String? xHandle; // X / Twitter (modern)
  String? youtube;
  String? tiktok;
  String? snapchat;

  // Legacy names expected by some older code:
  String? twitter; // alias of xHandle
  String? pinterest; // optional legacy
  String? whatsapp; // optional legacy

  Profile({
    required this.fullName,
    required this.role,
    required this.address,
    required this.phone,
    required this.email,
    required this.website,
    this.wellbeingLink = '',
    required this.bankSortCode,
    required this.bankAccountNumber,
    this.avatarPath,
    this.backgroundPath,
    this.backgroundColor,
    this.linkedin,
    this.instagram,
    this.facebook,
    this.xHandle,
    this.youtube,
    this.tiktok,
    this.snapchat,
    this.twitter, // legacy
    this.pinterest, // legacy
    this.whatsapp, // legacy
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'role': role,
        'address': address,
        'phone': phone,
        'email': email,
        'website': website,
        'wellbeingLink': wellbeingLink,
        'bankSortCode': bankSortCode,
        'bankAccountNumber': bankAccountNumber,
        'avatarPath': avatarPath,
        'backgroundPath': backgroundPath,
        // Use toARGB32() instead of the deprecated .value
        'backgroundColor': backgroundColor?.toARGB32(),
        'linkedin': linkedin,
        'instagram': instagram,
        'facebook': facebook,
        'xHandle': xHandle,
        'youtube': youtube,
        'tiktok': tiktok,
        'snapchat': snapchat,
        // legacy
        'twitter': twitter,
        'pinterest': pinterest,
        'whatsapp': whatsapp,
      };

  factory Profile.fromMap(Map<String, dynamic> map) {
    Color? color;
    final raw = map['backgroundColor'];
    final int? argb = _parseColorInt(raw);
    if (argb != null) color = Color(argb);

    // normalize legacy twitter -> xHandle if only one present
    final String? twitter = map['twitter']?.toString();
    final String? xHandle = map['xHandle']?.toString() ?? twitter;

    return Profile(
      fullName: map['fullName']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      website: map['website']?.toString() ?? '',
      wellbeingLink: map['wellbeingLink']?.toString() ?? '',
      bankSortCode: map['bankSortCode']?.toString() ?? '',
      bankAccountNumber: map['bankAccountNumber']?.toString() ?? '',
      avatarPath: map['avatarPath']?.toString(),
      backgroundPath: map['backgroundPath']?.toString(),
      backgroundColor: color,
      linkedin: map['linkedin']?.toString(),
      instagram: map['instagram']?.toString(),
      facebook: map['facebook']?.toString(),
      xHandle: xHandle,
      youtube: map['youtube']?.toString(),
      tiktok: map['tiktok']?.toString(),
      snapchat: map['snapchat']?.toString(),
      twitter: twitter,
      pinterest: map['pinterest']?.toString(),
      whatsapp: map['whatsapp']?.toString(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Profile.fromJson(String jsonStr) =>
      Profile.fromMap(jsonDecode(jsonStr) as Map<String, dynamic>);

  // ---- Convenience + Legacy compatibility getters ----
  static Profile defaultProfile() => Profile(
        fullName: 'Alkhadi Koroma',
        role: 'Professional Title · Flutter Developer',
        address: 'Flat 72 Priory Court, 1 Cheltenham Road, London SE15 3BG',
        phone: '07736806367',
        email: 'ngummariato@gmail.com',
        website: 'https://www.google.com',
        wellbeingLink: 'https://wellbeing.example.com',
        bankSortCode: '09-01-35',
        bankAccountNumber: '93087283',
        backgroundColor: Colors.grey.shade200,
      );

  static Profile fromJsonString(String s) => Profile.fromJson(s);

  // Some older code/tests use these aliases:
  String get name => fullName; // for tests like vcard_test.dart
  String get title => role;
  String? get wellbeingUrl => wellbeingLink.isNotEmpty ? wellbeingLink : null;
  String get effectiveDisplayName => fullName;

  /// Robustly parse a color from various legacy formats: int, "0xAARRGGBB",
  /// "#RRGGBB", or decimal strings.
  static int? _parseColorInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    final s0 = raw.toString().trim();
    if (s0.isEmpty) return null;

    // Hex with 0x or # prefixes
    String s = s0;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);

    // If hex digits only:
    final hexOnly = RegExp(r'^[0-9a-fA-F]+$');
    if (hexOnly.hasMatch(s)) {
      // If RRGGBB provide opaque alpha.
      if (s.length == 6) {
        s = 'FF$s';
      }
      // Now expect AARRGGBB
      if (s.length == 8) {
        return int.tryParse(s, radix: 16);
      }
    }

    // Decimal fallback
    return int.tryParse(s0);
  }
}
