// title=lib/services/deeplink_service.dart
// Simple, plugin-free parser for cardlink://u/<id> to unblock compilation.

import 'dart:async';

class DeepLinkEvent {
  final String id;

  const DeepLinkEvent(this.id);
}

class DeeplinkService {
  DeeplinkService._();

  static final DeeplinkService instance = DeeplinkService._();

  final _controller = StreamController<DeepLinkEvent>.broadcast();

  Stream<DeepLinkEvent> get events => _controller.stream;

  Future<void> init() async {
    // No-op. You can wire up platform channels or a plugin later if desired.
  }

  void handleUri(Uri uri) {
    final seg = uri.pathSegments;
    if (uri.scheme == 'cardlink' && seg.length >= 2 && seg.first == 'u') {
      _controller.add(DeepLinkEvent(seg[1]));
    }
  }

  String buildUserLink(String id) => 'cardlink://u/$id';
}
