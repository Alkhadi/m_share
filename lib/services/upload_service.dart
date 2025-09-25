// lib/services/upload_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<Uri?> uploadProfileToWeb({
  required Uint8List pdfBytes,
  required Map<String, dynamic> metadata,
  String endpoint = "https://mindpaylink.com/api/profile",
  String? uploadKey,
}) async {
  final request = http.MultipartRequest("POST", Uri.parse(endpoint));
  request.fields['meta'] = jsonEncode(metadata);

  request.files.add(
    http.MultipartFile.fromBytes(
      'pdf',
      pdfBytes,
      filename: 'profile.pdf',
      contentType: MediaType('application', 'pdf'),
    ),
  );

  if (uploadKey != null) {
    request.headers['x-upload-key'] = uploadKey;
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url != null) return Uri.parse(url);
  } else {
    throw Exception("Upload failed: ${response.statusCode} ${response.body}");
  }
  return null;
}
