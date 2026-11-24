import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/scene3d.dart';
import '../home/home_screen.dart';
import 'placement_screen.dart';

class _Slide {
  const _Slide(this.command, this.result, this.title, this.body);
  final String command;
  final String result;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    r'$ cipher --masuk',
    'membuka brankas data ... ok',
    'Masuk ke kota digital.',
    'Internet itu kota besar: ada taman, pasar, juga copet. Tiap level adalah satu distrik yang kamu jelajahi tanpa kecopetan.',
  ),
  _Slide(
    r'$ cipher --level',
    'LV.00 → LV.04 terdeteksi',
    'Naik level pelan-pelan.',
    'Mulai dari aman digital sehari-hari, lanjut ke jaringan, web, sampai kriptografi. Tiap modul cuma beberapa menit dan ada kuisnya.',
  ),
  _Slide(
    r'$ cipher --toolbox',
    'mode offline ... aktif',
    'Praktek, bukan hafalan.',
    'Toolbox kebuka seiring naik level. Semuanya jalan offline di HP kamu sendiri, gak ada data yang dikirim ke mana-mana.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PlacementScreen()),
      );
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skipToZero() async {
    await AppScope.read(context).completeOnboarding(0);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    final ring = _page == 2 ? C.orange : C.ok;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Text('CIPHER_',
                      style: mono(size: 15, color: C.accent, weight: FontWeight.w800, spacing: 3)),
                  const Spacer(),
                  Text('0${_page + 1} / 0${_slides.length}', style: mono()),
                ],
              ),
            ),
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  Positioned.fill(child: VaultScene(ring: ring)),
                  Positioned(
                    left: 24,
                    top: 14,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey(_page),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slide.command, style: mono(size: 11)),
                          const SizedBox(height: 4),
                          Text.rich(TextSpan(children: [
                            TextSpan(text: '> ', style: mono(size: 11)),
                            TextSpan(text: slide.result, style: mono(size: 11, color: C.ok)),
                          ])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 9,
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideText(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      width: i == _page ? 28 : 10,
                      decoration: BoxDecoration(
                        color: i == _page ? C.accent : C.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(
          onPressed: _next,
          child: Text(_isLast ? 'Mulai Tes Penempatan' : 'Lanjut'),
        ),
        if (_isLast)
          ChunkyButton.outline(
            onPressed: _skipToZero,
            child: const Text('Lewati, mulai dari LV.00'),
          ),
      ]),
    );
  }
}

class _SlideText extends StatelessWidget {
  const _SlideText({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slide.title, style: display(size: 31, height: 1.1)),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: const TextStyle(fontSize: 15.5, color: C.muted, height: 1.55),
          ),
        ],
      ),
    );
  }
}
