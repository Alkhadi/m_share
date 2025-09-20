import 'dart:io';

// Note: We removed the dependency on android_intent_plus because this
// plugin is unavailable on macOS and other platforms. Instead we
// rely solely on url_launcher to open bank apps via URL schemes and
// fall back to the app store or web.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bank_app_registry.dart';

class PaymentIntentService {
  /// Try to open bank app; if not available, fall back to App Store / Play.
  static Future<void> launchBankApp(BankApp app) async {
    // Attempt to open the bank app via its URL scheme on both Android and iOS.
    // Many banking apps expose a custom scheme (e.g. 'monzo://') which will
    // open the app if installed.  If the scheme fails to launch, we fall back
    // to the Play Store, App Store, or the bank's web homepage.
    final scheme = app.iosScheme; // Use the same scheme for both platforms
    if (scheme != null && scheme.isNotEmpty) {
      final Uri schemeUri = Uri.parse('$scheme://');
      if (await canLaunchUrl(schemeUri)) {
        await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Fallback for iOS: open App Store listing if available
    if (Platform.isIOS && app.iosAppStoreId != null) {
      final iosUrl = Uri.parse('https://apps.apple.com/app/id${app.iosAppStoreId}');
      await _launchExternal(iosUrl);
      return;
    }
    // Fallback for Android: open Play Store listing by package name
    if (Platform.isAndroid) {
      final Uri play = Uri.parse('https://play.google.com/store/apps/details?id=${app.androidPackage}');
      await _launchExternal(play);
      return;
    }
    // Fallback to web home if provided
    if (app.webHome != null) {
      await _launchExternal(app.webHome!);
    }
  }

  static Future<void> _launchExternal(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Unable to launch $url');
    }
  }
}
