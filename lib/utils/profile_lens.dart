// Robust ProfileLens utilities for CardLink Pro.
//
// These helpers provide a consistent way to read data from a [Profile]
// instance or a loosely typed map/dynamic object.  They include
// defensive checks so that missing fields don't throw exceptions.  Many
// methods accept [dynamic] so they can be called on either a Profile or
// a decoded JSON map.

// No UI widgets are used in this utility file; avoid pulling in
// material.dart to prevent unused import warnings.

/// A suite of static helpers for reading common fields off a profile
/// or dynamic object.  If the property is not found, null is returned.
class ProfileLens {
  // Aliases
  static String? name(dynamic p) => fullName(p);
  static String? title(dynamic p) => role(p);
  static String? phone(dynamic p) => phoneRaw(p);
  static String? address(dynamic p) => postalAddressOneLine(p);
  static String? wellbeing(dynamic p) => wellbeingUrl(p);

  /// Return a map of social links keyed by platform name.
  static Map<String, String> socials(dynamic p) {
    final m = <String, String>{};
    void add(String key, String? url) {
      if (url != null && url.isNotEmpty) m[key] = url;
    }
    add('Twitter', twitter(p));
    add('Facebook', facebook(p));
    add('Instagram', instagram(p));
    add('LinkedIn', linkedin(p));
    add('YouTube', youtube(p));
    add('TikTok', tiktok(p));
    add('Snapchat', snapchat(p));
    add('Pinterest', pinterest(p));
    add('WhatsApp', whatsapp(p));
    add('Wellbeing', wellbeingUrl(p));
    return m;
  }

  /// Return a map of bank details.  Keys are 'accountNumber', 'sortCode',
  /// 'iban' and 'reference'.  Values are empty strings if missing.
  static Map<String, String> bank(dynamic p) {
    final m = <String, String>{};
    final ac = bankAccountNumber(p);
    final sc = bankSortCode(p);
    final ib = bankIban(p);
    final ref = bankReference(p);
    if (ac != null && ac.isNotEmpty) m['accountNumber'] = ac;
    if (sc != null && sc.isNotEmpty) m['sortCode'] = sc;
    if (ib != null && ib.isNotEmpty) m['iban'] = ib;
    if (ref != null && ref.isNotEmpty) m['reference'] = ref;
    return m;
  }

  /// Return the effective avatar path if available; else a default.
  static String effectiveAvatar(dynamic p) {
    try {
      final a = _tryProp(p, 'effectiveAvatar');
      if (a is String && a.isNotEmpty) return a;
    } catch (_) {}
    final m = _asJsonMap(p);
    if (m != null) {
      final av = m['avatarAssetOrPath'] ?? m['avatar'];
      if (av is String && av.isNotEmpty) return av;
    }
    return 'assets/images/avatars/avatar_business.png';
  }

  /// Return the effective display name if available.
  static String effectiveDisplayName(dynamic p) {
    final nm = fullName(p);
    return nm ?? '';
  }

  static String? fullName(dynamic p) => _readString(p, ['fullName', 'name', 'displayName', 'titleName']);
  static String? role(dynamic p) => _readString(p, ['role', 'jobTitle', 'professionalTitle', 'position']);
  static String? phoneRaw(dynamic p) => _readString(p, ['phone', 'phoneNumber', 'mobile', 'tel']);
  static String? email(dynamic p) => _readString(p, ['email', 'emailAddress', 'mail']);
  static String? website(dynamic p) => _readString(p, ['website', 'site', 'url', 'link']);
  static String? wellbeingUrl(dynamic p) => _readUri(p, ['wellbeing', 'wellbeingUrl', 'wellbeingLink']);
  static String? postalAddressOneLine(dynamic p) {
    final one = _readString(p, ['addressOneLine', 'address', 'postalAddress']);
    if (one != null && one.trim().isNotEmpty) return one.trim();
    final parts = [
      _readString(p, ['street', 'addressLine1']),
      _readString(p, ['addressLine2']),
      _readString(p, ['city', 'town']),
      _readString(p, ['county', 'state', 'province']),
      _readString(p, ['postcode', 'zip', 'postalCode']),
      _readString(p, ['country'])
    ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim()).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  // Bank
  static String? bankSortCode(dynamic p) => _readString(p, ['sortCode', 'bankSortCode', 'sc', 'sortcode']);
  static String? bankAccountNumber(dynamic p) => _readString(p, ['accountNumber', 'bankAccountNumber', 'ac', 'accNumber']);
  static String? bankIban(dynamic p) => _readString(p, ['iban', 'bankIban']);
  static String? bankReference(dynamic p) => _readString(p, ['paymentReference', 'reference', 'bankReference']);

  // Social
  static String? twitter(dynamic p) => _readUri(p, ['twitter', 'x', 'xUrl']);
  static String? instagram(dynamic p) => _readUri(p, ['instagram', 'ig']);
  static String? facebook(dynamic p) => _readUri(p, ['facebook', 'fb']);
  static String? linkedin(dynamic p) => _readUri(p, ['linkedin', 'li']);
  static String? youtube(dynamic p) => _readUri(p, ['youtube', 'yt']);
  static String? tiktok(dynamic p) => _readUri(p, ['tiktok', 'tt']);
  static String? snapchat(dynamic p) => _readUri(p, ['snapchat', 'sc']);
  static String? pinterest(dynamic p) => _readUri(p, ['pinterest', 'pt']);
  static String? whatsapp(dynamic p) => _readUri(p, ['whatsapp', 'wa']);

  /// Construct a Google Maps search URL for the profile's address.
  static String mapsUrl(dynamic p) {
    final addr = postalAddressOneLine(p) ?? '';
    if (addr.isEmpty) return '';
    return 'https://maps.google.com/?q=${Uri.encodeComponent(addr)}';
  }

  // ---------- private helpers ----------
  static String? _readString(dynamic p, List<String> keys) {
    try {
      for (final k in keys) {
        final v = _tryProp(p, k);
        if (v is String && v.trim().isNotEmpty) return v;
        if (v != null) return v.toString();
      }
    } catch (_) {}
    try {
      final m = _asJsonMap(p);
      if (m != null) {
        for (final k in keys) {
          final v = m[k];
          if (v is String && v.trim().isNotEmpty) return v;
          if (v != null) return v.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _readUri(dynamic p, List<String> keys) {
    final s = _readString(p, keys);
    if (s == null || s.trim().isEmpty) return null;
    final t = s.trim();
    if (t.startsWith(RegExp(r'https?://|mailto:|tel:|whatsapp:'))) return t;
    return 'https://$t';
  }

  static dynamic _tryProp(dynamic p, String key) {
    if (p is Map) return p[key];
    try {
      final m = _asJsonMap(p);
      if (m != null) return m[key];
    } catch (_) {}
    return null;
  }

  static Map<String, dynamic>? _asJsonMap(dynamic p) {
    try {
      final m = p.toJson();
      if (m is Map<String, dynamic>) return m;
    } catch (_) {}
    return null;
  }
}