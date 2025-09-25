import 'package:http/http.dart' as http;

/// Utility to shorten URLs via is.gd (no API key needed).
class ShortUrlService {
  static Future<String> shorten(String longUrl) async {
    final encodedUrl = Uri.encodeComponent(longUrl);
    final uri = Uri.parse(
      'https://is.gd/create.php?format=simple&url=$encodedUrl',
    );
    try {
      final response = await http.get(uri);
      // If the API returns a valid shortened URL, return it
      if (response.statusCode == 200 &&
          response.body.trim().startsWith('http')) {
        return response.body.trim();
      }
    } catch (_) {}
    // Fallback to the original URL on failure
    return longUrl;
  }
}
