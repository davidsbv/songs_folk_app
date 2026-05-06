import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_branding.dart';
import 'core/db_factory_init.dart';
import 'core/supabase_config.dart';
import 'models/app_appearance.dart';
import 'repositories/app_appearance_repository.dart';
import 'screens/welcome_screen.dart';
import 'services/theme_prefs_service.dart';
import 'theme/branding_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabaseFactory();

  if (isSupabaseConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const MyApp());
}

/// Punto de entrada: tema local por usuario + colores/fondo remotos via Supabase.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppAppearanceRepository _appearanceRepo = AppAppearanceRepository();
  final ThemePrefsService _themePrefs = ThemePrefsService();

  AppAppearance _appearance = AppAppearance.fallback;
  ThemeMode _themeMode = ThemeMode.system;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final loaded = await Future.wait<Object?>([
      _themePrefs.readThemeMode(),
      _appearanceRepo.fetchPublic(),
    ]);
    if (!mounted) return;
    setState(() {
      _themeMode = loaded[0]! as ThemeMode;
      _appearance = loaded[1]! as AppAppearance;
      _ready = true;
    });
  }

  Future<void> _loadAppearance() async {
    final next = await _appearanceRepo.fetchPublic();
    if (!mounted) return;
    setState(() => _appearance = next);
  }

  Future<void> _setUserThemeMode(ThemeMode mode) async {
    await _themePrefs.writeThemeMode(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAppearance();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Cancionero Folk',
      locale: const Locale('es', 'ES'),
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(
        appearance: _appearance,
        brightness: Brightness.light,
      ),
      darkTheme: buildAppTheme(
        appearance: _appearance,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      builder: (context, child) {
        return AppBranding(
          appearance: _appearance,
          themeMode: _themeMode,
          refreshAppearance: _loadAppearance,
          setUserThemeMode: _setUserThemeMode,
          child: AppearanceBackground(
            appearance: _appearance,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const WelcomeScreen(),
    );
  }
}
