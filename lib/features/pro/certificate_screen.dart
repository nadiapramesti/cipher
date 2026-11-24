import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../core/backup.dart';
import '../../core/models.dart';
import '../../l10n/strings.dart';
import '../../widgets/common.dart';

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// ID sertifikat buat dicek ulang: checksum dari nama + level + tanggal.
String certificateId(String name, String levelCode, String date) =>
    fnv32('$name|$levelCode|$date').toUpperCase();

/// Isi nama, lihat pratinjau, lalu bagikan sertifikat sebagai PDF.
class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.level});
  final Level level;

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  late final _name = TextEditingController(text: AppScope.read(context).certName);
  bool _busy = false;
  final _today = _date(DateTime.now());

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await AppScope.read(context).setCertName(name);
      final bytes = await _buildPdf(name);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cipher-${widget.level.code.toLowerCase().replaceAll('.', '')}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
          subject: tr('ce_share_subject', {'l': widget.level.code}));
    } catch (_) {
      if (mounted) showInfo(context, tr('ce_fail'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<int>> _buildPdf(String name) async {
    final title = pw.Font.ttf(await rootBundle.load('assets/fonts/ChakraPetch-Bold.ttf'));
    final body = pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
    final p = paletteFor(AppScope.read(context).accent, dark: false);
    final accent = PdfColor.fromInt(p.accent.toARGB32());
    final ink = PdfColor.fromInt(0xFF1B1530);
    final soft = PdfColor.fromInt(0xFF625880);
    final count = widget.level.moduleIds.length;
    final id = certificateId(name, widget.level.code, _today);

    final doc = pw.Document(title: 'Cipher ${widget.level.code}', author: 'Cipher');
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 3),
          borderRadius: pw.BorderRadius.circular(18),
        ),
        padding: const pw.EdgeInsets.fromLTRB(48, 40, 48, 36),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CIPHER_', style: pw.TextStyle(font: title, fontSize: 16, color: accent, letterSpacing: 3)),
            pw.Spacer(),
            pw.Text(tr('ce_pdf_title'), style: pw.TextStyle(font: title, fontSize: 34, color: ink)),
            pw.SizedBox(height: 18),
            pw.Text(tr('ce_pdf_given'), style: pw.TextStyle(font: body, fontSize: 14, color: soft)),
            pw.SizedBox(height: 6),
            pw.Text(name, style: pw.TextStyle(font: bold, fontSize: 30, color: ink)),
            pw.SizedBox(height: 14),
            pw.Text(
              tr('ce_pdf_body', {'l': '${widget.level.code} ${widget.level.title}', 'n': count}),
              style: pw.TextStyle(font: body, fontSize: 14, color: ink, lineSpacing: 4),
            ),
            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(tr('ce_pdf_date'), style: pw.TextStyle(font: body, fontSize: 10, color: soft)),
                  pw.Text(_today, style: pw.TextStyle(font: bold, fontSize: 13, color: ink)),
                ]),
                pw.SizedBox(width: 48),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(tr('ce_pdf_id'), style: pw.TextStyle(font: body, fontSize: 10, color: soft)),
                  pw.Text(id, style: pw.TextStyle(font: bold, fontSize: 12, color: ink, letterSpacing: 1.5)),
                ]),
                pw.Spacer(),
                pw.Text('cipher · ${tr('ce_pdf_tagline')}', style: pw.TextStyle(font: body, fontSize: 10, color: soft)),
              ],
            ),
          ],
        ),
      ),
    ));
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();

    return Scaffold(
      appBar: AppBar(title: Text(tr('ce_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(tr('ce_lead'), style: TextStyle(color: C.textSoft, height: 1.45)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            keyboardType: TextInputType.name,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: tr('ce_name'),
              hintText: tr('ce_name_hint'),
              prefixIcon: Icon(Icons.badge_outlined, color: C.muted),
            ),
          ),
          const SizedBox(height: 18),
          MonoTag(tr('ce_preview')),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 297 / 210,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: C.accent, width: 2.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CIPHER_', style: mono(size: 9, color: paletteFor(AppScope.of(context).accent, dark: false).accent, spacing: 2)),
                  const Spacer(),
                  Text(tr('ce_pdf_title'),
                      style: const TextStyle(fontFamily: kDisplay, fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1B1530))),
                  const SizedBox(height: 6),
                  Text(name.isEmpty ? tr('ce_name_hint') : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: name.isEmpty ? const Color(0xFF9A93AE) : const Color(0xFF1B1530))),
                  const SizedBox(height: 4),
                  Text(
                    tr('ce_pdf_body', {'l': '${widget.level.code} ${widget.level.title}', 'n': widget.level.moduleIds.length}),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9.5, height: 1.35, color: Color(0xFF3D3460)),
                  ),
                  const Spacer(),
                  Text(_today, style: const TextStyle(fontSize: 9, color: Color(0xFF625880))),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: name.isEmpty || _busy ? null : _share,
          child: Text(_busy ? tr('ce_making') : tr('ce_share')),
        ),
      ]),
    );
  }
}
