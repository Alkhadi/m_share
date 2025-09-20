// No direct file or platform APIs are used in this service.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Note: We removed the dependency on android_intent_plus to avoid build
// issues on platforms where the plugin is unavailable (e.g. macOS).  We
// instead rely solely on url_launcher to open bank-specific URL schemes on
// both Android and iOS.  If a bank app is installed and supports the
// provided scheme, it will open; otherwise the call will fail and we
// display a snackbar to inform the user.
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';

/// Service responsible for launching internet banking applications with
/// appropriate fall‑backs and copying details to the clipboard.  The
/// implementation attempts to open a known banking app on the device
/// using the android_intent_plus package on Android and URL schemes on
/// iOS.  If no supported app is installed, a snackbar is displayed
/// informing the user that the details have been copied to the clipboard
/// instead.  A confirmation dialog is always shown before anything
/// happens to avoid accidentally triggering an external action.  This
/// class is stateless and uses only static methods.
class BankLauncher {
  const BankLauncher._();

  /// Presents a confirmation dialog and, on approval, copies the name,
  /// sort code and account number to the clipboard before attempting to
  /// launch the banking app specified by [bank].  If [bank] is null the
  /// default behaviour copies the details and exits without launching
  /// anything.  This helper should be called from a widget context
  /// whenever the user taps on their bank details.
  static Future<void> confirmAndLaunch(
    BuildContext context,
    Profile profile, {
    String? bank,
  }) async {
    final String message =
        'Do you want to send money to ${profile.fullName}?';
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    // Copy details to clipboard (Name + sort code + account number)
    final details =
        '${profile.fullName}\n${profile.bankSortCode}\n${profile.bankAccountNumber}';
    await Clipboard.setData(ClipboardData(text: details));
    // Attempt to launch the selected bank app via URL scheme.  If the
    // launch fails or [bank] is null, we simply show a copy confirmation.
    if (bank != null && bank.isNotEmpty) {
      final bool launched = await _tryLaunchBankApp(bank, profile);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No banking app found. Bank details copied to clipboard. Paste into your app.'),
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details copied to clipboard. Paste into your app.'),
          ),
        );
      }
    }
  }

  /// Internal helper that encapsulates the platform specific logic for
  /// launching known banking applications.  The method returns true if
  /// anything was successfully launched, otherwise false.  Deep links
  /// are attempted via URL schemes on both Android and iOS.  If no
  /// supported app is installed the method returns false.
  static Future<bool> _tryLaunchBankApp(String bank, Profile profile) async {
    final sort = profile.bankSortCode.replaceAll('-', '');
    final account = profile.bankAccountNumber;
    final name = Uri.encodeComponent(profile.fullName);

    // Mapping of bank identifiers to URL schemes.  A scheme like
    // 'monzo://' will open the Monzo app if installed.  We use the
    // same scheme on both Android and iOS to avoid platform-specific
    // dependencies.
    const Map<String, String> bankSchemes = {
      'Monzo': 'monzo://',
      'Starling': 'starling://',
      'Barclays': 'barclays://',
      'NatWest': 'natwest://',
      'Revolut': 'revolut://',
      'Santander': 'santander://',
      'HSBC': 'hsbc://',
      'Lloyds': 'lloyds://',
      'Halifax': 'halifax://',
      'Nationwide': 'nationwide://',
    };
    final String? scheme = bankSchemes[bank];
    if (scheme == null) return false;
    final String urlString =
        '$scheme/pay?sortCode=$sort&accountNumber=$account&name=$name';
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {
      // ignore errors, fall through to return false below
    }
    return false;
  }
}