import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_state.dart';
import 'app/theme.dart';
import 'core/content_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/common.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CipherBoot());
}

/// Muat materi + progres dulu, baru masuk app.
class CipherBoot extends StatefulWidget {
  const CipherBoot({super.key});

  @override
  State<CipherBoot> createState() => _CipherBootState();
}

class _CipherBootState extends State<CipherBoot> {
  late Future<AppState> _future;

  @override
  void initState() {
    super.initState();
    _future = _init();
  }

  Future<AppState> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final content = await Content.load();
    return AppState(prefs, content);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) return CipherApp(state: snap.data!);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: snap.hasError
              ? _BootError(
                  error: '${snap.error}',
                  onRetry: () => setState(() => _future = _init()),
                )
              : const _Splash(),
        );
      },
    );
  }
}

class CipherApp extends StatelessWidget {
  const CipherApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Cipher',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: state.onboardingDone
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('CIPHER_',
                style: mono(size: 26, color: C.amber, weight: FontWeight.w800, spacing: 4)),
            const SizedBox(height: 18),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: C.line,
                valueColor: AlwaysStoppedAnimation(C.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: StateMessage(
              glyph: '!! ERR',
              color: C.red,
              title: 'Materi gagal dimuat',
              body: 'Coba buka ulang. Kalau masih gagal, kemungkinan file materi rusak.\n\n$error',
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        FilledButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ]),
    );
  }
}
