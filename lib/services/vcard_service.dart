/// Helper to build vCard text representations.
class VCardService {
  static String buildSimple({
    required String fullName,
    String? email,
    String? phone,
    String? url,
  }) {
    final b = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('FN:$fullName');
    if (email != null && email.isNotEmpty) {
      b.writeln('EMAIL;TYPE=INTERNET:$email');
    }
    if (phone != null && phone.isNotEmpty) {
      b.writeln('TEL;TYPE=CELL:$phone');
    }
    if (url != null && url.isNotEmpty) {
      b.writeln('URL:$url');
    }
    b.writeln('END:VCARD');
    return b.toString();
  }

  /// Build a vCard from a [profile] object.  Convenience for tests expecting
  /// `buildVCard(p)`.  This maps to [buildSimple] using values extracted via
  /// dynamic properties.
  static String buildVCard(dynamic profile) {
    final name = profile?.fullName ?? profile?.name ?? '';
    final email = profile?.email;
    final phone = profile?.phone;
    final url = profile?.website;
    return buildSimple(
      fullName: name,
      email: email,
      phone: phone,
      url: url,
    );
  }
}

/// A top‑level helper mirroring [VCardService.buildVCard].  This allows
/// legacy code and tests to call `buildVCard(p)` directly instead of
/// `VCardService.buildVCard(p)`.  See [VCardService.buildVCard] for details.
String buildVCard(dynamic profile) => VCardService.buildVCard(profile);