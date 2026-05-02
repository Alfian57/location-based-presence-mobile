import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'core/presentation/splash_screen.dart';
part 'features/auth/data/auth_repository.dart';
part 'features/auth/presentation/login_page.dart';
part 'features/shell/presentation/authenticated_shell.dart';
part 'features/presence/data/presence_repository.dart';
part 'features/presence/presentation/home_page.dart';
part 'features/leave/data/leave_repository.dart';
part 'features/leave/presentation/leave_page.dart';
part 'features/history/data/history_repository.dart';
part 'features/history/presentation/history_page.dart';
part 'features/profile/data/profile_repository.dart';
part 'features/profile/presentation/profile_page.dart';
part 'core/presentation/shared_widgets.dart';
part 'core/domain/platform_models.dart';
part 'core/data/api_client.dart';
part 'core/platform/platform_bridge.dart';
part 'core/presentation/ui_helpers.dart';

const _apiBaseEnvKey = 'API_BASE_URL';
const _fallbackApiBase = 'http://10.0.2.2:8000/api/mobile';

const _warnaPrimer = Color(0xFF0F766E);
const _warnaPrimerGelap = Color(0xFF134E4A);
const _warnaAksen = Color(0xFFF59E0B);
const _warnaBiru = Color(0xFF2563EB);
const _warnaLatar = Color(0xFFF1F5F9);
const _warnaPanel = Color(0xFFFFFFFF);
const _warnaTeksUtama = Color(0xFF0F172A);
const _warnaTeksRedup = Color(0xFF64748B);
const _warnaGaris = Color(0xFFDDE7EF);
const _radiusKartu = 8.0;
const _assetLogoAplikasi = 'assets/images/app_logo.png';
const _assetAvatarPlaceholder = 'assets/images/avatar_placeholder.png';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(PresensiApp(apiBase: apiBaseDariEnv()));
}

class PresensiApp extends StatefulWidget {
  const PresensiApp({super.key, this.apiBase = _fallbackApiBase});

  final String apiBase;

  @override
  State<PresensiApp> createState() => _PresensiAppState();
}

class _PresensiAppState extends State<PresensiApp> {
  String? _token;
  Map<String, dynamic>? _user;
  bool _booting = true;

  String get _apiBase => widget.apiBase;

  ApiClient get _client => ApiClient(baseUrl: _apiBase, token: _token);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final storedToken = await PlatformBridge.readValue('token');
    _token = storedToken;

    if (_token != null) {
      try {
        final profile = await _client.get('/profil') as Map<String, dynamic>;
        _user = Map<String, dynamic>.from(profile['pengguna'] as Map);
      } catch (_) {
        await PlatformBridge.clearValue('token');
        _token = null;
      }
    }

    if (mounted) setState(() => _booting = false);
  }

  Future<void> _authenticate(String token, Map<String, dynamic> user) async {
    await PlatformBridge.saveValue('token', token);
    setState(() {
      _token = token;
      _user = user;
    });
  }

  Future<void> _logout() async {
    try {
      await _client.post('/autentikasi/keluar');
    } catch (_) {
      // Token lokal tetap dibersihkan walaupun server tidak terjangkau.
    }
    await PlatformBridge.clearValue('token');
    setState(() {
      _token = null;
      _user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presensi Guru',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: _warnaPrimer,
              brightness: Brightness.light,
            ).copyWith(
              primary: _warnaPrimer,
              secondary: _warnaAksen,
              tertiary: _warnaBiru,
              surface: _warnaPanel,
            ),
        scaffoldBackgroundColor: _warnaLatar,
        appBarTheme: const AppBarTheme(
          backgroundColor: _warnaLatar,
          foregroundColor: _warnaTeksUtama,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: _warnaTeksUtama,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusKartu)),
            borderSide: BorderSide(color: _warnaGaris),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusKartu)),
            borderSide: BorderSide(color: _warnaGaris),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusKartu)),
            borderSide: BorderSide(color: _warnaPrimer, width: 1.4),
          ),
          isDense: true,
          labelStyle: TextStyle(color: _warnaTeksRedup),
          prefixIconColor: _warnaPrimer,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusKartu),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            foregroundColor: _warnaPrimerGelap,
            side: const BorderSide(color: _warnaGaris),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radiusKartu),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusKartu)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _warnaPrimer.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withValues(alpha: 0.10),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _warnaPrimerGelap
                  : _warnaTeksRedup,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_radiusKartu)),
            side: BorderSide(color: _warnaGaris),
          ),
        ),
      ),
      home: _booting
          ? const SplashScreen()
          : _token == null
          ? LoginPage(apiBase: _apiBase, onAuthenticated: _authenticate)
          : AuthenticatedShell(
              client: _client,
              user: _user ?? const {},
              onLogout: _logout,
              onUserChanged: (user) => setState(() => _user = user),
            ),
    );
  }
}
