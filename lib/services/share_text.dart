import '../models/profile.dart';
import '../utils/profile_lens.dart';

/// Utility functions for rendering a shareable text string from a Profile.
///
/// This file is a forwarder for legacy code that used a different renderer.
String renderShareText(Profile p) {
  final b = StringBuffer();
  final name = ProfileLens.name(p);
  final title = ProfileLens.title(p);
  final phone = ProfileLens.phone(p);
  final email = ProfileLens.email(p);
  final website = ProfileLens.website(p);
  final wellbeing = ProfileLens.wellbeing(p);
  final address = ProfileLens.address(p);
  final socials = ProfileLens.socials(p);
  final bank = ProfileLens.bank(p);

  b.writeln((title == null || title.isEmpty) ? name ?? '' : '$name — $title');
  if ((address ?? '').isNotEmpty) b.writeln(address);

  if ((phone ?? '').isNotEmpty) b.writeln(telUri(phone!).toString());
  if ((email ?? '').isNotEmpty) b.writeln(mailtoUri(email!).toString());
  if ((website ?? '').isNotEmpty) b.writeln(webUri(website!).toString());
  if ((wellbeing ?? '').isNotEmpty) {
    b.writeln('Wellbeing: ${webUri(wellbeing!).toString()}');
  }
  if ((address ?? '').isNotEmpty) {
    b.writeln(mapsUri(address!).toString());
  }
  if (socials.isNotEmpty) {
    b.writeln('\n— Social —');
    for (final entry in socials.entries) {
      b.writeln('${entry.key}  ${webUri(entry.value)}');
    }
  }
  if (bank.isNotEmpty) {
    final pieces = [
      if ((bank['accountNumber'] ?? '').isNotEmpty)
        'Ac number: ${bank['accountNumber']}',
      if ((bank['sortCode'] ?? '').isNotEmpty)
        'Sc Code: ${bank['sortCode']}',
    ];
    final bankLine = pieces.join('    ');
    if (bankLine.isNotEmpty) b.writeln('\n$bankLine');
  }
  return b.toString().trim();
}

/// Build a tel URI from a phone string.  Adds the tel: scheme and trims.
Uri telUri(String phone) {
  final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  return Uri.parse('tel:+$normalized'.replaceAll('++', '+'));
}

/// Build a mailto URI from an email string.
Uri mailtoUri(String email) => Uri.parse('mailto:${email.trim()}');

/// Build a web URI; prefix with https:// if necessary.
Uri webUri(String url) {
  final u = url.trim();
  return Uri.parse(u.startsWith(RegExp(r'https?://')) ? u : 'https://$u');
}

/// Build a Google Maps URI from an address.
Uri mapsUri(String address) {
  final q = Uri.encodeComponent(address.trim());
  return Uri.parse('https://maps.google.com/?q=$q');
}