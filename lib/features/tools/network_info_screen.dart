import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

/// Info jaringan HP sendiri + demo DNS lookup. Pakai dart:io, tanpa plugin.
class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  late Future<List<NetworkInterface>> _ifaces = _load();
  final _domain = TextEditingController();
  bool _looking = false;
  List<InternetAddress>? _dns;
  String? _dnsError;

  Future<List<NetworkInterface>> _load() =>
      NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  String _kind(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('wlan') || n.startsWith('wifi') || n.startsWith('en')) return tr('ni_wifi');
    if (n.startsWith('rmnet') || n.startsWith('ccmni') || n.startsWith('pdp') || n.startsWith('v4-rmnet')) {
      return tr('ni_cell');
    }
    if (n.startsWith('tun') || n.startsWith('ppp') || n.startsWith('ipsec')) return tr('ni_vpn');
    return tr('ni_other');
  }

  /// Alamat privat (cuma berlaku di jaringan lokal), bukan alamat publik internet.
  bool _isPrivate(InternetAddress a) {
    if (a.type != InternetAddressType.IPv4) return a.address.toLowerCase().startsWith('fe80') || a.address.toLowerCase().startsWith('fd');
    final p = a.address.split('.').map(int.tryParse).toList();
    if (p.length != 4 || p.contains(null)) return false;
    final x = p[0]!, y = p[1]!;
    return x == 10 || (x == 172 && y >= 16 && y <= 31) || (x == 192 && y == 168) || (x == 100 && y >= 64 && y <= 127);
  }

  Future<void> _lookup() async {
    final host = _domain.text.trim().replaceFirst(RegExp(r'^https?://'), '').split('/').first;
    if (host.isEmpty) return;
    setState(() {
      _looking = true;
      _dns = null;
      _dnsError = null;
    });
    try {
      final res = await InternetAddress.lookup(host).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _dns = res);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dnsError = tr('ni_dns_fail', {'h': host}));
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('tool_net_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(tr('ni_lead'), style: TextStyle(color: C.textSoft, height: 1.45)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MonoTag(tr('ni_ifaces'))),
              TextButton.icon(
                onPressed: () => setState(() => _ifaces = _load()),
                icon: Icon(Icons.refresh_rounded, size: 18, color: C.accent),
                label: Text(tr('ni_refresh'), style: TextStyle(color: C.accent, fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  side: BorderSide(color: C.accentDeep),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<NetworkInterface>>(
            future: _ifaces,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snap.data ?? const <NetworkInterface>[];
              if (snap.hasError || list.isEmpty) {
                return StateMessage(glyph: '[--]', title: tr('ni_none_title'), body: tr('ni_none_body'));
              }
              return Column(
                children: [
                  for (final it in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(_kind(it.name), style: display(size: 17))),
                                MonoTag(it.name, filled: true),
                              ],
                            ),
                            const SizedBox(height: 10),
                            for (final a in it.addresses)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 44,
                                      child: Text(a.type == InternetAddressType.IPv4 ? 'IPv4' : 'IPv6',
                                          style: mono(size: 11, color: C.accent, weight: FontWeight.w700)),
                                    ),
                                    Expanded(
                                      child: SelectableText(a.address,
                                          style: mono(size: 12.5, color: C.text, spacing: 0)),
                                    ),
                                    if (_isPrivate(a)) MonoTag(tr('ni_private'), color: C.ok),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Panel(
            color: C.accentTint,
            borderColor: C.accentDeep,
            child: Text(tr('ni_private_note'), style: TextStyle(height: 1.5, color: C.text)),
          ),
          const SizedBox(height: 24),
          Text(tr('ni_dns_title'), style: display(size: 20)),
          const SizedBox(height: 6),
          Text(tr('ni_dns_lead'), style: TextStyle(color: C.textSoft, height: 1.45)),
          const SizedBox(height: 12),
          TextField(
            controller: _domain,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: tr('ni_domain'),
              hintText: tr('ni_domain_hint'),
              prefixIcon: Icon(Icons.dns_outlined, color: C.muted),
            ),
          ),
          const SizedBox(height: 12),
          if (_dnsError != null)
            StateMessage(glyph: '!! DNS', color: C.red, title: tr('ni_dns_fail_title'), body: _dnsError!)
          else if (_dns != null)
            Panel(
              borderColor: C.okDeep,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoTag(tr('ni_dns_result', {'n': _dns!.length}), color: C.ok),
                  const SizedBox(height: 8),
                  for (final a in _dns!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(a.address, style: mono(size: 13, color: C.text, spacing: 0)),
                    ),
                  const SizedBox(height: 6),
                  Text(tr('ni_dns_explain'), style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.4)),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: _looking || _domain.text.trim().isEmpty ? null : _lookup,
          child: Text(_looking ? tr('ni_looking') : tr('ni_lookup')),
        ),
      ]),
    );
  }
}
