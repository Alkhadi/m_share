class BankApp {
  final String name;
  final String androidPackage;
  final String? iosAppStoreId;
  final String? iosScheme;
  final Uri? webHome;

  BankApp({
    required this.name,
    required this.androidPackage,
    this.iosAppStoreId,
    this.iosScheme,
    this.webHome,
  });
}

// Not const because Uri.parse() is not const.
final bankApps = <BankApp>[
  BankApp(
    name: 'Monzo',
    androidPackage: 'co.uk.getmondo',
    iosAppStoreId: '1001084647',
    iosScheme: 'monzo',
    webHome: Uri.parse('https://monzo.com'),
  ),
  BankApp(
    name: 'Starling',
    androidPackage: 'com.starlingbank.android',
    iosAppStoreId: '1191347413',
    iosScheme: 'starling',
    webHome: Uri.parse('https://www.starlingbank.com'),
  ),
];
