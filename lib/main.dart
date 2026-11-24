import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_state.dart';
import 'app/theme.dart';
import 'core/content_repository.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'widgets/common.dart';
import 'l10n/strings.dart';

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
    L.lang = AppState.initialLang(prefs);
    final content = await Content.load(L.code);
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
          theme: buildTheme(C.palette),
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

/// Root app. Dengerin perubahan tema / mode / bahasa, terus gambar ulang
/// semua layar tanpa ngereset navigasi.
class CipherApp extends StatefulWidget {
  const CipherApp({super.key, required this.state});

  final AppState state;

  @override
  State<CipherApp> createState() => _CipherAppState();
}

class _CipherAppState extends State<CipherApp> with WidgetsBindingObserver {
  late String _look = _lookKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onStateChanged);
    _applyPalette();
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _dark => switch (widget.state.themeMode) {
        AppThemeMode.dark => true,
        AppThemeMode.light => false,
        AppThemeMode.system =>
          WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
      };

  String _lookKey() => '${widget.state.accent.name}-$_dark-${L.code}';

  void _applyPalette() => C.use(paletteFor(widget.state.accent, dark: _dark));

  void _refreshIfLookChanged() {
    final key = _lookKey();
    if (key == _look) return;
    _look = key;
    _applyPalette();
    setState(() {});
    // warna & teks dibaca langsung dari C / tr(), jadi semua elemen ditandai
    // buat digambar ulang supaya ikut berubah.
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  void _onStateChanged() => _refreshIfLookChanged();

  @override
  void didChangePlatformBrightness() => _refreshIfLookChanged();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: MaterialApp(
        title: 'Cipher',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(C.palette),
        // ikon status bar ikut terang/gelap sesuai tema
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: C.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        ),
        home: widget.state.onboardingDone ? const HomeScreen() : const OnboardingScreen(),
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
                style: mono(size: 26, color: C.accent, weight: FontWeight.w800, spacing: 4)),
            const SizedBox(height: 18),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: C.line,
                valueColor: AlwaysStoppedAnimation(C.accent),
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
              title: tr('err_title'),
              body: '${tr('err_body')}\n\n$error',
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActions(children: [
        ChunkyButton(onPressed: onRetry, child: Text(tr('retry'))),
      ]),
    );
  }
}
