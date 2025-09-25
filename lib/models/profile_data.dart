class ProfileData {
  final String name;
  final String title;
  final String ref;
  final String addr;
  final String email;
  final String phone;
  final String site;
  final String? avatarUrl;
  final String? bankName;
  final String? ac;
  final String? sort;
  final String? iban;
  final String wellbeingLink;
  final String? x;
  final String? ig;
  final String? yt;
  final String? ln;

  const ProfileData({
    required this.name,
    required this.title,
    required this.ref,
    required this.addr,
    required this.email,
    required this.phone,
    required this.site,
    this.avatarUrl,
    this.bankName,
    this.ac,
    this.sort,
    this.iban,
    this.wellbeingLink = '',
    this.x,
    this.ig,
    this.yt,
    this.ln,
  });

  /// Default profile
  factory ProfileData.defaultProfile() {
    return const ProfileData(
      name: 'Alkhadi Koroma',
      title: 'Flutter Developer',
      ref: 'M SHARE',
      addr: 'Flat 72 Priory Court, 1 Cheltenham Road, London SE15 3BG',
      email: 'ngummariato@gmail.com',
      phone: '07736806367',
      site: 'https://mindpaylink.com',
      bankName: 'Santander',
      ac: '93087283',
      sort: '09-01-35',
      iban: 'GB81ABBY09013593087283',
      wellbeingLink: 'https://wellbeing.example.com',
    );
  }

  /// Generate canonical profile URL
  Uri profileUrl() {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return Uri.parse('https://mindpaylink.com/p/$slug');
  }
}
