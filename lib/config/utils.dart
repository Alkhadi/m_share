/// Builds a compact query string for your web links.
/// Short keys (n, ph, em, etc.) keep the URL smaller.
/// Empty values are omitted.
String buildQuery({
  required String name,
  String? phone,
  String? email,
  String? site,
  String? addr,
  String? avatar,
  String? acc,
  String? sort,
  String? iban,
  String ref = 'M SHARE',
  String? x,
  String? ig,
  String? yt,
  String? ln,
}) {
  String enc(String? s) => Uri.encodeComponent(s ?? '');
  final parts = <String>[];

  void add(String key, String? value) {
    if (value != null && value.trim().isNotEmpty) {
      parts.add('$key=${enc(value)}');
    }
  }

  add('n', name);
  add('ph', phone);
  add('em', email);
  add('s', site);
  add('a', addr);
  add('av', avatar);
  add('ac', acc);
  add('sc', sort);
  add('ib', iban);
  add('r', ref);
  add('x', x);
  add('ig', ig);
  add('yt', yt);
  add('ln', ln);

  return parts.isNotEmpty ? ('?' + parts.join('&')) : '';
}
