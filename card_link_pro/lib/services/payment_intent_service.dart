import 'package:url_launcher/url_launcher.dart';

import 'bank_registry.dart';

/// Service to open bank apps with prefilled payment details.
class PaymentIntentService {
  static Future<void> openInstalledBankApp({
    required BankApp bank,
    required String account,
    required String sortCode,
    String? name,
    String? iban,
    String? reference,
  }) async {
    final uri = bank.buildDeepLink(
      account: account,
      sortCode: sortCode,
      name: name,
      iban: iban,
      reference: reference,
    );
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}