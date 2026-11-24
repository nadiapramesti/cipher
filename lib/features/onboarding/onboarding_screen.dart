import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart';
import 'placement_screen.dart';

class _Slide {
  const _Slide(this.glyph, this.title, this.body);
  final String glyph;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    '> _',
    'Internet itu kota besar.',
    'Ada taman, ada pasar, ada juga copet. Cipher ngajarin kamu jalan-jalan di dalamnya tanpa kecopetan.',
  ),
  _Slide(
    '[LV]',
    'Naik level pelan-pelan.',
    'Mulai dari aman digital sehari-hari, lanjut ke jaringan, web, sampai kriptografi. Tiap modul cuma beberapa menit dan ada kuisnya.',
  ),
  _Slide(
    '{ok}',
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
      duration: const Duration(milliseconds: 320),
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
                      style: mono(size: 15, color: C.amber, weight: FontWeight.w800, spacing: 3)),
                  const Spacer(),
                  Text('0${_page + 1} / 0${_slides.length}', style: mono()),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      width: i == _page ? 28 : 10,
                      decoration: BoxDecoration(
                        color: i == _page ? C.amber : C.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(
          onPressed: _next,
          child: Text(_isLast ? 'Mulai Tes Penempatan' : 'Lanjut'),
        ),
        if (_isLast)
          OutlinedButton(
            onPressed: _skipToZero,
            child: const Text('Lewati, mulai dari LV.00'),
          ),
      ]),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: C.surface,
                  border: Border.all(color: C.line),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: GridBackdrop(
                  child: Center(
                    child: Text(
                      slide.glyph,
                      style: mono(
                        size: 64,
                        color: C.amber,
                        weight: FontWeight.w800,
                        spacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.body,
            style: const TextStyle(fontSize: 15.5, color: C.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
