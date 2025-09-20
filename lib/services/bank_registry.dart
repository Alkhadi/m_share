import 'package:url_launcher/url_launcher.dart';

class BankApp {
  final String name;

  /// A deep link template string used to construct a payment URL.  We store
  /// the template as a string so it can be provided in const constructors.
  /// Example: `monzo://payments?action=pay&account={ac}&sort={sc}&ref={ref}`.
  final String? deepLinkTemplate;

  /// A link to the app store if the user does not have the bank app installed.
  final Uri? storeUrl;

  const BankApp({required this.name, this.deepLinkTemplate, this.storeUrl});

  /// Build a deep link by replacing placeholders in [deepLinkTemplate].
  /// Supported placeholders: {ac}, {sc}, {name}, {iban}, {ref}.  Returns null
  /// if no template was provided.
  Uri? buildDeepLink({
    required String account,
    required String sortCode,
    String? name,
    String? iban,
    String? reference,
  }) {
    final template = deepLinkTemplate;
    if (template == null || template.isEmpty) return null;
    var s = template;
    s = s.replaceAll('{ac}', Uri.encodeComponent(account));
    s = s.replaceAll('{sc}', Uri.encodeComponent(sortCode));
    s = s.replaceAll('{name}', Uri.encodeComponent(name ?? ''));
    s = s.replaceAll('{iban}', Uri.encodeComponent(iban ?? ''));
    s = s.replaceAll('{ref}', Uri.encodeComponent(reference ?? ''));
    return Uri.parse(s);
  }
}

class BankRegistry {
  static final ukDefault = <BankApp>[
    const BankApp(
      name: 'Monzo',
      deepLinkTemplate:
          'monzo://payments?action=pay&account={ac}&sort={sc}&ref={ref}',
    ),
    const BankApp(
      name: 'Starling',
      deepLinkTemplate:
          'starling://pay?sortCode={sc}&accountNumber={ac}&reference={ref}',
    ),
    const BankApp(name: 'Barclays'),
    const BankApp(name: 'NatWest'),
    const BankApp(
      name: 'Revolut',
      deepLinkTemplate: 'revolut://send?iban={iban}&reference={ref}',
    ),
  ];

  static Future<void> open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}