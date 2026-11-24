/// Analisis struktur URL secara offline: gak ada request ke internet.

enum UrlRisk { info, warn, danger }

class UrlFinding {
  const UrlFinding(this.key, this.risk, [this.args = const {}]);
  final String key; // kunci string l10n
  final UrlRisk risk;
  final Map<String, Object> args;
}

class UrlReport {
  const UrlReport({
    required this.valid,
    this.scheme = '',
    this.host = '',
    this.domain = '',
    this.subdomain = '',
    this.path = '',
    this.params = const [],
    this.findings = const [],
  });

  final bool valid;
  final String scheme;
  final String host;
  final String domain; // domain yang didaftarkan (misal bca.co.id)
  final String subdomain;
  final String path;
  final List<(String, String)> params;
  final List<UrlFinding> findings;

  int get score => findings.fold(0, (s, f) => s + switch (f.risk) { UrlRisk.danger => 3, UrlRisk.warn => 1, UrlRisk.info => 0 });

  /// 0 aman-aman aja, 1 waspada, 2 mencurigakan
  int get verdict => score >= 3 ? 2 : (score >= 1 ? 1 : 0);
}

const _brands = [
  'bca', 'bri', 'bni', 'mandiri', 'btn', 'cimb', 'jenius', 'dana', 'ovo', 'gopay', 'linkaja', 'shopee', 'tokopedia',
  'lazada', 'bukalapak', 'gojek', 'grab', 'google', 'facebook', 'instagram', 'whatsapp', 'tiktok', 'paypal',
  'apple', 'icloud', 'microsoft', 'netflix', 'telkomsel', 'pln', 'pajak', 'bpjs',
];
const _shorteners = ['bit.ly', 's.id', 'tinyurl.com', 'cutt.ly', 't.co', 'shorturl.at', 'rebrand.ly', 'is.gd', 'goo.gl', 'ow.ly'];
const _riskyTlds = ['xyz', 'top', 'click', 'icu', 'buzz', 'cfd', 'sbs', 'rest', 'cam', 'monster', 'shop', 'live', 'online', 'site'];
const _secondLevel = ['co', 'ac', 'go', 'or', 'web', 'my', 'sch', 'net', 'com', 'org', 'gov', 'edu', 'mil', 'biz', 'ponpes', 'desa'];

String registrableDomain(String host) {
  final parts = host.split('.');
  if (parts.length <= 2) return host;
  final tld = parts.last;
  final sl = parts[parts.length - 2];
  final take = (tld.length == 2 && _secondLevel.contains(sl)) ? 3 : 2;
  return parts.sublist(parts.length - (take > parts.length ? parts.length : take)).join('.');
}

/// Ganti karakter yang sering dipakai buat nyamar (0→o, 1→l, rn→m, dst).
String _deLeet(String s) => s
    .replaceAll('0', 'o')
    .replaceAll('1', 'l')
    .replaceAll('3', 'e')
    .replaceAll('4', 'a')
    .replaceAll('5', 's')
    .replaceAll('rn', 'm')
    .replaceAll('vv', 'w');

UrlReport analyzeUrl(String raw) {
  var input = raw.trim();
  if (input.isEmpty) return const UrlReport(valid: false);
  final hadScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(input);
  if (!hadScheme) input = 'http://$input';

  final Uri uri;
  try {
    uri = Uri.parse(input);
  } catch (_) {
    return const UrlReport(valid: false);
  }
  final host = uri.host.toLowerCase();
  if (host.isEmpty || (!host.contains('.') && host != 'localhost')) return const UrlReport(valid: false);

  final f = <UrlFinding>[];
  final isIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) || host.contains(':');
  final domain = isIp ? host : registrableDomain(host);
  final sub = (isIp || host == domain) ? '' : host.substring(0, host.length - domain.length - 1);
  final label = domain.split('.').first;

  if (!hadScheme) {
    f.add(const UrlFinding('ui_no_scheme', UrlRisk.info));
  } else if (uri.scheme == 'http') {
    f.add(const UrlFinding('ui_http', UrlRisk.warn));
  }
  if (uri.userInfo.isNotEmpty || (raw.contains('@') && raw.indexOf('@') < raw.indexOf(host))) {
    f.add(UrlFinding('ui_at', UrlRisk.danger, {'h': host}));
  }
  if (isIp) f.add(const UrlFinding('ui_ip', UrlRisk.danger));
  if (host.contains('xn--')) f.add(const UrlFinding('ui_puny', UrlRisk.danger));
  if (_shorteners.contains(host)) f.add(const UrlFinding('ui_short', UrlRisk.warn));

  if (!isIp) {
    final tld = host.split('.').last;
    if (_riskyTlds.contains(tld)) f.add(UrlFinding('ui_tld', UrlRisk.warn, {'t': '.$tld'}));

    // merek di subdomain/label tapi domain aslinya bukan milik merek itu
    if (!_brands.contains(label)) {
      final subParts = sub.split(RegExp(r'[.-]'));
      final labelParts = label.split('-');
      final clean = _deLeet(label);
      for (final b in _brands) {
        if (subParts.contains(b)) {
          f.add(UrlFinding('ui_brand_sub', UrlRisk.danger, {'b': b, 'd': domain}));
          break;
        }
        if (labelParts.length > 1 && labelParts.contains(b)) {
          f.add(UrlFinding('ui_brand_extra', UrlRisk.danger, {'b': b, 'd': domain}));
          break;
        }
        if (clean != label && clean.split('-').contains(b)) {
          f.add(UrlFinding('ui_lookalike', UrlRisk.danger, {'b': b, 'l': label}));
          break;
        }
      }
    }
    if (label.split('-').length >= 3) f.add(const UrlFinding('ui_hyphen', UrlRisk.warn));
    if (sub.split('.').where((s) => s.isNotEmpty).length >= 3) f.add(const UrlFinding('ui_deep', UrlRisk.warn));
  }

  final low = raw.toLowerCase();
  if (RegExp(r'\.(apk|exe|scr|bat|msi)(\?|$)').hasMatch(uri.path.toLowerCase())) {
    f.add(const UrlFinding('ui_file', UrlRisk.danger));
  }
  if (['login', 'verif', 'update', 'hadiah', 'claim', 'blokir', 'secure', 'akun'].any(low.contains)) {
    f.add(const UrlFinding('ui_bait', UrlRisk.info));
  }
  if (raw.length > 120) f.add(const UrlFinding('ui_long', UrlRisk.info));

  return UrlReport(
    valid: true,
    scheme: hadScheme ? uri.scheme : '',
    host: host,
    domain: domain,
    subdomain: sub,
    path: uri.path.isEmpty ? '/' : uri.path,
    params: [for (final e in uri.queryParametersAll.entries) for (final v in e.value) (e.key, v)],
    findings: f,
  );
}
