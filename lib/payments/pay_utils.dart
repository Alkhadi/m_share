Uri buildPayUniversalLink({
  required String name,
  required String sortCode,
  required String accountNumber,
  String? iban,
  String? bic,
  String? amount,
  String? reference,
}) {
  final qp = <String, String>{
    'name': name,
    'acc': accountNumber,
    'sc': sortCode,
  };
  if ((iban ?? '').isNotEmpty) qp['iban'] = iban!;
  if ((bic ?? '').isNotEmpty) qp['bic'] = bic!;
  if ((amount ?? '').isNotEmpty) qp['amount'] = amount!;
  if ((reference ?? '').isNotEmpty) qp['ref'] = reference!;

  return Uri.https('cardlink.pro', '/pay', qp);
}

/// EPC QR content for SEPA credit transfer (works widely across EU apps).
/// Minimal form:
/// ServiceTag:       "BCD"
/// Version:          "001"
/// CharacterSet:     "1" (UTF-8)
/// Identification:   "SCT"
/// BIC:              bic
/// Name:             name
/// IBAN:             iban
/// Amount:           "EUR12.34" (optional)
/// Purpose / Ref / Remittance: leave empty or use "REFERENCE"
String buildEpcQrText({
  required String name,
  required String iban,
  String? bic,
  String? amountEur, // "12.34" (no currency symbol)
  String? reference, // remittance info
}) {
  final lines = <String>[
    'BCD', // Service tag
    '001', // Version
    '1', // Charset UTF-8
    'SCT', // Service code
    bic ?? '', // BIC optional
    name, // Name
    iban, // IBAN
    amountEur != null && amountEur.isNotEmpty ? 'EUR$amountEur' : '',
    '', // Purpose
    '', // Remittance (structured)
    reference ?? '' // Remittance (unstructured)
  ];
  return lines.join('\n');
}
