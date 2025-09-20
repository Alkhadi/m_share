/// Utility helpers for constructing and launching common URIs.
///
/// These functions normalise phone numbers, build `tel:`, `mailto:`, and
/// arbitrary web URIs, generate Google Maps search links for addresses, and
/// provide a convenience wrapper for launching URIs using url_launcher.
library;

import 'package:url_launcher/url_launcher.dart';

/// Trim surrounding whitespace from an E.164 phone number.  Returns an empty
/// string if [e164] is null.
String normalizePhone(String? e164) => (e164 ?? '').trim();

/// Build a `tel:` URI from a phone number in E.164 format (without spaces
/// or hyphens).  Uses [normalizePhone] to clean the input.
Uri telUri(String? e164) => Uri(scheme: 'tel', path: normalizePhone(e164));

/// Build a `mailto:` URI from an email address.  Optional [subject] and
/// [body] query parameters will be included if non‑empty.  If no query
/// parameters are provided, the `queryParameters` argument will be null.
Uri mailtoUri(String? email, {String? subject, String? body}) {
  final params = <String, String>{};
  if (subject != null && subject.isNotEmpty) params['subject'] = subject;
  if (body != null && body.isNotEmpty) params['body'] = body;
  return Uri(
    scheme: 'mailto',
    path: (email ?? '').trim(),
    queryParameters: params.isEmpty ? null : params,
  );
}

/// Normalise a URL and ensure it has an HTTP or HTTPS scheme.  If [url] is
/// empty or null, returns a placeholder `https://`.  If [url] already
/// starts with `http://` or `https://`, it is returned unmodified.
Uri webUri(String? url) {
  final trimmed = (url ?? '').trim();
  if (trimmed.isEmpty) return Uri.parse('https://');
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return Uri.parse(trimmed);
  }
  return Uri.parse('https://$trimmed');
}

/// Create a Google Maps search link for [address].  If [address] is null
/// or empty, the query will be empty as well.  This uses a secure HTTPS
/// URL with the `www.google.com/maps/search/` path.
Uri mapsUri(String? address) {
  return Uri.https('www.google.com', '/maps/search/', {
    'q': (address ?? '').trim(),
  });
}

/// Attempt to launch the provided [uri] using url_launcher.  Returns true
/// if the URL was successfully launched, false otherwise.  This wraps
/// [canLaunchUrl] and [launchUrl] for convenience.
Future<bool> tryLaunch(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}