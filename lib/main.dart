import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _defaultApiBase = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/mobile',
);

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

void main() {
  runApp(const PresensiApp());
}

class PresensiApp extends StatefulWidget {
  const PresensiApp({super.key});

  @override
  State<PresensiApp> createState() => _PresensiAppState();
}

class _PresensiAppState extends State<PresensiApp> {
  final String _apiBase = _defaultApiBase;
  String? _token;
  Map<String, dynamic>? _user;
  bool _booting = true;

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

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_radiusKartu),
                  boxShadow: [
                    BoxShadow(
                      color: _warnaPrimer.withValues(alpha: 0.14),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Image(
                    image: AssetImage(_assetLogoAplikasi),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Presensi Guru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _warnaTeksUtama,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Menyiapkan sesi aplikasi',
                style: TextStyle(color: _warnaTeksRedup),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.apiBase,
    required this.onAuthenticated,
  });

  final String apiBase;
  final Future<void> Function(String token, Map<String, dynamic> user)
  onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _activationMode = false;
  bool _showPassword = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final device = await PlatformBridge.deviceInfo();
      final client = ApiClient(baseUrl: widget.apiBase);
      final response =
          await client.post(
                _activationMode
                    ? '/autentikasi/aktivasi'
                    : '/autentikasi/masuk',
                body: {
                  'email': _email.text.trim(),
                  'kata_sandi': _password.text,
                  'id_perangkat': device['device_id'],
                  'nama_perangkat': device['device_name'],
                  'platform': device['platform'],
                },
              )
              as Map<String, dynamic>;

      await widget.onAuthenticated(
        response['token'] as String,
        Map<String, dynamic>.from(response['pengguna'] as Map),
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on PlatformException catch (error) {
      setState(() => _error = error.message ?? 'Perangkat tidak bisa dibaca.');
    } catch (error) {
      setState(() => _error = 'Masuk gagal: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _error = null);
    try {
      final client = ApiClient(baseUrl: widget.apiBase);
      final response = await client.post(
        '/autentikasi/reset-kata-sandi',
        body: {'email': _email.text.trim()},
      );
      if (!mounted) return;
      tampilkanNotifikasi(context, response['pesan'] as String);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = layarXxs(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: paddingHalaman(context),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 32 : 48),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _LoginHero(),
                        SizedBox(height: compact ? 14 : 20),
                        const _AuthFacts(),
                        SizedBox(height: compact ? 14 : 18),
                        Panel(
                          padding: EdgeInsets.all(compact ? 14 : 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _activationMode
                                    ? 'Aktivasi akun'
                                    : 'Masuk akun',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _activationMode
                                    ? 'Gunakan email dan kata sandi dari admin sekolah.'
                                    : 'Gunakan akun guru yang sudah terdaftar.',
                                style: const TextStyle(
                                  color: _warnaTeksRedup,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SegmentedButton<bool>(
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  visualDensity: compact
                                      ? VisualDensity.compact
                                      : VisualDensity.standard,
                                  padding: WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(
                                      horizontal: compact ? 8 : 12,
                                    ),
                                  ),
                                ),
                                segments: const [
                                  ButtonSegment<bool>(
                                    value: false,
                                    icon: Icon(Icons.login),
                                    label: Text('Masuk'),
                                  ),
                                  ButtonSegment<bool>(
                                    value: true,
                                    icon: Icon(Icons.person_add_alt_1),
                                    label: Text('Aktivasi'),
                                  ),
                                ],
                                selected: {_activationMode},
                                onSelectionChanged: _loading
                                    ? null
                                    : (values) => setState(
                                        () => _activationMode = values.first,
                                      ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                ErrorBox(message: _error!),
                              ],
                              const SizedBox(height: 16),
                              TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _password,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  if (!_loading) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword
                                        ? 'Sembunyikan kata sandi'
                                        : 'Tampilkan kata sandi',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _loading ? null : _submit,
                                icon: _loading
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        _activationMode
                                            ? Icons.verified_outlined
                                            : Icons.login,
                                      ),
                                label: Text(
                                  _activationMode
                                      ? 'Aktivasi & Masuk'
                                      : 'Masuk',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.end,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  TextButton(
                                    onPressed: _loading ? null : _resetPassword,
                                    child: const Text('Reset Kata Sandi'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radiusKartu),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_warnaPrimerGelap, _warnaPrimer, _warnaBiru],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F766E),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 44 : 52,
            height: compact ? 44 : 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_radiusKartu),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Image(
                image: AssetImage(_assetLogoAplikasi),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presensi Guru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 22 : null,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masuk, aktivasi perangkat, dan validasi presensi dalam satu aplikasi.',
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFacts extends StatelessWidget {
  const _AuthFacts();

  @override
  Widget build(BuildContext context) {
    const facts = [
      _AuthFact(
        icon: Icons.location_on_outlined,
        label: 'Lokasi',
        value: 'GPS',
      ),
      _AuthFact(
        icon: Icons.verified_user_outlined,
        label: 'Perangkat',
        value: 'Terikat',
      ),
      _AuthFact(icon: Icons.schedule_outlined, label: 'Jadwal', value: 'Aktif'),
    ];

    if (layarXxs(context)) {
      return Column(
        children: [
          for (var index = 0; index < facts.length; index++) ...[
            facts[index],
            if (index < facts.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var index = 0; index < facts.length; index++) ...[
          Expanded(child: facts[index]),
          if (index < facts.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _AuthFact extends StatelessWidget {
  const _AuthFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: _warnaGaris),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _warnaPrimer, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _warnaTeksRedup),
          ),
        ],
      ),
    );
  }
}

class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({
    super.key,
    required this.client,
    required this.user,
    required this.onLogout,
    required this.onUserChanged,
  });

  final ApiClient client;
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  int _index = 0;

  Future<void> _confirmLogout() async {
    final confirmed = await konfirmasiTindakan(
      context,
      judul: 'Keluar dari akun?',
      pesan: 'Sesi presensi di perangkat ini akan ditutup.',
      labelSetuju: 'Keluar',
      ikon: Icons.logout,
    );
    if (confirmed && mounted) {
      await widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);
    final pages = [
      HomePage(client: widget.client),
      LeavePage(client: widget.client),
      HistoryPage(client: widget.client),
      ProfilePage(
        client: widget.client,
        user: widget.user,
        onLogout: widget.onLogout,
        onUserChanged: widget.onUserChanged,
      ),
    ];
    const titles = ['Presensi', 'Pengajuan Izin', 'Riwayat', 'Profil'];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: compact ? 8 : 16,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_radiusKartu),
                border: Border.all(color: _warnaGaris),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Image(
                  image: AssetImage(_assetLogoAplikasi),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Presensi Guru', overflow: TextOverflow.ellipsis),
                  Text(
                    titles[_index],
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _warnaTeksRedup,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        height: compact ? 62 : 72,
        labelBehavior: compact
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fingerprint),
            label: 'Presensi',
          ),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Izin'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  final ApiClient client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  bool _clocking = false;
  String? _error;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _shiftPayload;
  LocationSnapshot? _location;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today =
          await widget.client.get('/presensi/hari-ini') as Map<String, dynamic>;
      final shift =
          await widget.client.get('/jadwal-kerja') as Map<String, dynamic>;
      LocationSnapshot? location;
      try {
        location = await PlatformBridge.location();
      } on PlatformException catch (error) {
        _error = error.message;
      }
      setState(() {
        _attendance = today['presensi'] == null
            ? null
            : Map<String, dynamic>.from(today['presensi'] as Map);
        _shiftPayload = shift;
        _location = location;
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clock(String type) async {
    setState(() {
      _clocking = true;
      _error = null;
    });
    try {
      final location = await PlatformBridge.location();
      final device = await PlatformBridge.deviceInfo();
      final response =
          await widget.client.post(
                '/presensi/catat',
                body: {
                  'jenis': type,
                  'latitude': location.latitude,
                  'longitude': location.longitude,
                  'akurasi': location.accuracy,
                  'id_perangkat': device['device_id'],
                  'lokasi_palsu': location.mockedLocation,
                  'waktu_klien': DateTime.now().toIso8601String(),
                },
              )
              as Map<String, dynamic>;
      setState(() {
        _attendance = Map<String, dynamic>.from(response['presensi'] as Map);
        _location = location;
      });
      if (!mounted) return;
      tampilkanNotifikasi(context, response['pesan'] as String);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } on PlatformException catch (error) {
      setState(() => _error = error.message ?? 'Lokasi tidak tersedia.');
    } finally {
      if (mounted) setState(() => _clocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = _shiftPayload?['lokasi_sekolah'] == null
        ? null
        : Map<String, dynamic>.from(_shiftPayload!['lokasi_sekolah'] as Map);
    final shift = _shiftPayload?['jadwal_kerja'] == null
        ? null
        : Map<String, dynamic>.from(_shiftPayload!['jadwal_kerja'] as Map);
    final distance = school != null && _location != null
        ? haversineMeters(
            _location!.latitude,
            _location!.longitude,
            (school['latitude'] as num).toDouble(),
            (school['longitude'] as num).toDouble(),
          )
        : null;
    final radius = (school?['radius_meter'] as num?)?.toInt();
    final insideRadius = distance != null && radius != null
        ? distance <= radius
        : null;
    final attendanceStatus =
        (_attendance?['status'] as String?) ?? 'belum_presensi';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: paddingHalaman(context),
        children: [
          PageHeader(
            icon: Icons.today_outlined,
            title: 'Presensi Hari Ini',
            subtitle: formatTanggalLengkap(DateTime.now()),
            trailing: IconButton.filledTonal(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          _AttendanceHero(
            status: attendanceStatus,
            masuk: formatIsoTime(_attendance?['jam_masuk_pada'] as String?),
            pulang: formatIsoTime(_attendance?['jam_pulang_pada'] as String?),
            loading: _loading,
          ),
          const SizedBox(height: 12),
          ResponsivePair(
            first: MetricTile(
              icon: Icons.business_center_outlined,
              label: 'Jadwal Kerja',
              value: shift?['nama']?.toString() ?? '-',
              color: _warnaPrimer,
            ),
            second: MetricTile(
              icon: Icons.schedule_outlined,
              label: 'Jam Kerja',
              value: shift == null
                  ? '-'
                  : '${shift['jam_masuk']} - ${shift['jam_pulang']}',
              color: _warnaBiru,
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.fingerprint,
                  title: 'Aksi Presensi',
                  subtitle: 'Gunakan sesuai jadwal sekolah.',
                ),
                const SizedBox(height: 12),
                ResponsivePair(
                  stretchNarrow: true,
                  first: FilledButton.icon(
                    onPressed: _clocking ? null : () => _clock('masuk'),
                    icon: _clocking
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Presensi Masuk'),
                  ),
                  second: OutlinedButton.icon(
                    onPressed: _clocking ? null : () => _clock('pulang'),
                    icon: const Icon(Icons.logout),
                    label: const Text('Presensi Pulang'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  icon: Icons.location_on_outlined,
                  title: 'Validasi Lokasi',
                  subtitle: school?['nama']?.toString() ?? 'Lokasi sekolah',
                  trailing: LocationStatusPill(
                    insideRadius: insideRadius,
                    mocked: _location?.mockedLocation == true,
                  ),
                ),
                const SizedBox(height: 12),
                ResponsivePair(
                  first: MetricTile(
                    icon: Icons.gps_fixed_outlined,
                    label: 'Akurasi GPS',
                    value: _location == null ? '-' : '${_location!.accuracy} m',
                    color: _warnaPrimer,
                    compact: true,
                  ),
                  second: MetricTile(
                    icon: Icons.social_distance_outlined,
                    label: 'Jarak Sekolah',
                    value: distance == null ? '-' : '$distance m',
                    color: insideRadius == false ? _warnaAksen : _warnaBiru,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 10),
                ResponsivePair(
                  first: MetricTile(
                    icon: Icons.shield_outlined,
                    label: 'Lokasi Palsu',
                    value: _location?.mockedLocation == true
                        ? 'Terdeteksi'
                        : 'Tidak',
                    color: _location?.mockedLocation == true
                        ? const Color(0xFFB91C1C)
                        : _warnaPrimer,
                    compact: true,
                  ),
                  second: MetricTile(
                    icon: Icons.radio_button_checked,
                    label: 'Radius Diizinkan',
                    value: radius == null ? '-' : '$radius m',
                    color: _warnaAksen,
                    compact: true,
                  ),
                ),
                if (insideRadius == false || _location?.mockedLocation == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: InlineNotice(
                      icon: Icons.warning_amber_outlined,
                      message: _location?.mockedLocation == true
                          ? 'Lokasi palsu terdeteksi. Presensi bisa ditolak oleh sistem.'
                          : 'Posisi Anda berada di luar radius sekolah.',
                      color: const Color(0xFFB45309),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeavePage extends StatefulWidget {
  const LeavePage({super.key, required this.client});

  final ApiClient client;

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final _start = TextEditingController(text: dateOnly(DateTime.now()));
  final _end = TextEditingController(text: dateOnly(DateTime.now()));
  final _reason = TextEditingController();
  String _type = 'izin';
  PickedDocument? _document;
  List<dynamic> _items = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await widget.client.get('/pengajuan-izin') as Map<String, dynamic>;
      setState(() => _items = response['data'] as List<dynamic>);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) controller.text = dateOnly(picked);
  }

  Future<void> _pickDocument() async {
    final document = await PlatformBridge.pickDocument();
    if (document != null) setState(() => _document = document);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.client.multipartLeave({
        'jenis': _type,
        'tanggal_mulai': _start.text,
        'tanggal_selesai': _end.text,
        'alasan': _reason.text,
      }, _document);
      _reason.clear();
      setState(() => _document = null);
      await _load();
      if (!mounted) return;
      tampilkanNotifikasi(context, 'Pengajuan berhasil dikirim.');
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: paddingHalaman(context),
        children: [
          PageHeader(
            icon: Icons.assignment_outlined,
            title: 'Izin, Sakit, Cuti',
            subtitle: 'Ajukan ketidakhadiran dengan dokumen pendukung.',
            trailing: IconButton.filledTonal(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.edit_calendar_outlined,
                  title: 'Form Pengajuan',
                  subtitle: 'Isi tanggal dan alasan secara singkat.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LeaveTypeChip(
                      label: 'Izin',
                      icon: Icons.event_available_outlined,
                      selected: _type == 'izin',
                      onSelected: () => setState(() => _type = 'izin'),
                    ),
                    LeaveTypeChip(
                      label: 'Sakit',
                      icon: Icons.local_hospital_outlined,
                      selected: _type == 'sakit',
                      onSelected: () => setState(() => _type = 'sakit'),
                    ),
                    LeaveTypeChip(
                      label: 'Cuti',
                      icon: Icons.beach_access_outlined,
                      selected: _type == 'cuti',
                      onSelected: () => setState(() => _type = 'cuti'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ResponsivePair(
                  first: TextField(
                    controller: _start,
                    readOnly: true,
                    onTap: () => _pickDate(_start),
                    decoration: const InputDecoration(
                      labelText: 'Mulai',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  second: TextField(
                    controller: _end,
                    readOnly: true,
                    onTap: () => _pickDate(_end),
                    decoration: const InputDecoration(
                      labelText: 'Selesai',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Alasan',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                ResponsivePair(
                  stretchNarrow: true,
                  first: DocumentTile(
                    name: _document?.name ?? 'Belum ada dokumen',
                    attached: _document != null,
                  ),
                  second: OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Dokumen'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: const Text('Kirim Pengajuan'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(
            icon: Icons.fact_check_outlined,
            title: 'Status Pengajuan',
            subtitle: '${_items.length} pengajuan tersimpan',
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_items.isEmpty)
            const EmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'Belum ada pengajuan',
              message: 'Pengajuan izin, sakit, atau cuti akan tampil di sini.',
            )
          else
            ..._items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SubmissionCard(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.client});

  final ApiClient client;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _month = TextEditingController(text: monthOnly(DateTime.now()));
  bool _loading = true;
  String? _error;
  List<dynamic> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _month.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await widget.client.get(
                '/presensi/riwayat?bulan=${Uri.encodeQueryComponent(_month.text)}',
              )
              as Map<String, dynamic>;
      setState(() => _items = response['data'] as List<dynamic>);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = <String, int>{};
    for (final raw in _items) {
      final item = Map<String, dynamic>.from(raw as Map);
      final status = item['status']?.toString() ?? '-';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: paddingHalaman(context),
        children: [
          PageHeader(
            icon: Icons.history_outlined,
            title: 'Riwayat Presensi',
            subtitle: 'Pantau rekap kehadiran bulanan.',
            trailing: IconButton.filledTonal(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Muat ulang',
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  icon: Icons.filter_alt_outlined,
                  title: 'Filter Bulan',
                  subtitle: 'Format bulan menggunakan YYYY-MM.',
                ),
                const SizedBox(height: 12),
                ResponsivePair(
                  stretchNarrow: true,
                  first: TextField(
                    controller: _month,
                    decoration: const InputDecoration(
                      labelText: 'Bulan YYYY-MM',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                  second: FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.search),
                    label: const Text('Filter'),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          if (!_loading && _items.isNotEmpty) ...[
            ResponsivePair(
              first: MetricTile(
                icon: Icons.event_available_outlined,
                label: 'Tepat Waktu',
                value: '${statusCounts['hadir'] ?? 0} hari',
                color: _warnaPrimer,
              ),
              second: MetricTile(
                icon: Icons.warning_amber_outlined,
                label: 'Terlambat',
                value: '${statusCounts['terlambat'] ?? 0} hari',
                color: _warnaAksen,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_items.isEmpty)
            const EmptyState(
              icon: Icons.history_toggle_off_outlined,
              title: 'Belum ada riwayat',
              message: 'Data presensi untuk bulan ini belum tersedia.',
            )
          else
            ..._items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HistoryCard(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.client,
    required this.user,
    required this.onLogout,
    required this.onUserChanged,
  });

  final ApiClient client;
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;
  final ValueChanged<Map<String, dynamic>> onUserChanged;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _saving = false;

  Map<String, dynamic> get teacher => widget.user['guru'] == null
      ? {}
      : Map<String, dynamic>.from(widget.user['guru'] as Map);

  Future<void> _confirmLogout() async {
    final confirmed = await konfirmasiTindakan(
      context,
      judul: 'Keluar dari akun?',
      pesan: 'Anda perlu masuk lagi untuk mencatat presensi berikutnya.',
      labelSetuju: 'Keluar',
      ikon: Icons.logout,
    );
    if (confirmed && mounted) {
      await widget.onLogout();
    }
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _saving = true);
    try {
      final response =
          await widget.client.put(
                '/profil/pengaturan-notifikasi',
                body: {'notifikasi_aktif': value},
              )
              as Map<String, dynamic>;
      widget.onUserChanged(
        Map<String, dynamic>.from(response['pengguna'] as Map),
      );
      if (!mounted) return;
      tampilkanNotifikasi(
        context,
        value ? 'Notifikasi diaktifkan.' : 'Notifikasi dinonaktifkan.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      tampilkanNotifikasi(context, error.message, tipe: TipeNotifikasi.gagal);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: paddingHalaman(context),
      children: [
        PageHeader(
          icon: Icons.person_outline,
          title: 'Profil',
          subtitle: 'Data akun dan pengaturan aplikasi.',
        ),
        const SizedBox(height: 12),
        ProfileHero(user: widget.user, teacher: teacher),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                icon: Icons.badge_outlined,
                title: 'Informasi Guru',
                subtitle: 'Data ini dikelola oleh admin sekolah.',
              ),
              const SizedBox(height: 12),
              ResponsivePair(
                first: MetricTile(
                  icon: Icons.badge_outlined,
                  label: 'NIP',
                  value:
                      teacher['nip']?.toString() ??
                      widget.user['nomor_pegawai']?.toString() ??
                      '-',
                  color: _warnaPrimer,
                  compact: true,
                ),
                second: MetricTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Mata Pelajaran',
                  value: teacher['mata_pelajaran']?.toString() ?? '-',
                  color: _warnaBiru,
                  compact: true,
                ),
              ),
              const SizedBox(height: 10),
              MetricTile(
                icon: Icons.schedule_outlined,
                label: 'Jadwal Kerja',
                value: teacher['jadwal_kerja']?.toString() ?? '-',
                color: _warnaAksen,
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _warnaPrimer.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(_radiusKartu),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: _warnaPrimerGelap,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Notifikasi',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Pengingat presensi dan status pengajuan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                value: teacher['notifikasi_aktif'] == true,
                onChanged: _saving ? null : _setNotifications,
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 40 : 44,
          height: compact ? 40 : 44,
          decoration: BoxDecoration(
            color: _warnaPrimer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(_radiusKartu),
          ),
          child: Icon(icon, color: _warnaPrimerGelap, size: compact ? 20 : 22),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  fontSize: compact ? 19 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _warnaTeksRedup, height: 1.25),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _warnaPrimer.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(_radiusKartu),
          ),
          child: Icon(icon, color: _warnaPrimerGelap, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _warnaTeksUtama,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _warnaTeksRedup, height: 1.25),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final small = layarXxs(context) || compact;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: _warnaGaris),
      ),
      child: Row(
        children: [
          Container(
            width: small ? 34 : 38,
            height: small ? 34 : 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(_radiusKartu),
            ),
            child: Icon(icon, color: color, size: small ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _warnaTeksRedup,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _warnaTeksUtama,
                    fontWeight: FontWeight.w900,
                    fontSize: small ? 14 : 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceHero extends StatelessWidget {
  const _AttendanceHero({
    required this.status,
    required this.masuk,
    required this.pulang,
    required this.loading,
  });

  final String status;
  final String masuk;
  final String pulang;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radiusKartu),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_warnaPrimerGelap, _warnaPrimer, _warnaBiru],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(status: status, onDark: true),
              const Spacer(),
              if (loading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusLabel(status),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
              fontSize: compact ? 22 : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catatan presensi untuk ${formatTanggalPendek(DateTime.now())}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ResponsivePair(
            first: _HeroTime(icon: Icons.login, label: 'Masuk', value: masuk),
            second: _HeroTime(
              icon: Icons.logout,
              label: 'Pulang',
              value: pulang,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTime extends StatelessWidget {
  const _HeroTime({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LocationStatusPill extends StatelessWidget {
  const LocationStatusPill({
    super.key,
    required this.insideRadius,
    required this.mocked,
  });

  final bool? insideRadius;
  final bool mocked;

  @override
  Widget build(BuildContext context) {
    final label = mocked
        ? 'Ditolak'
        : insideRadius == null
        ? 'Menunggu'
        : insideRadius!
        ? 'Valid'
        : 'Di Luar';
    final color = mocked || insideRadius == false
        ? const Color(0xFFB91C1C)
        : insideRadius == null
        ? _warnaTeksRedup
        : _warnaPrimer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class InlineNotice extends StatelessWidget {
  const InlineNotice({
    super.key,
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveTypeChip extends StatelessWidget {
  const LeaveTypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? _warnaPrimerGelap : _warnaTeksUtama,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: _warnaPrimer.withValues(alpha: 0.13),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? _warnaPrimer : _warnaGaris),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusKartu),
      ),
    );
  }
}

class DocumentTile extends StatelessWidget {
  const DocumentTile({super.key, required this.name, required this.attached});

  final String name;
  final bool attached;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: attached
            ? _warnaPrimer.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: attached ? _warnaPrimer : _warnaGaris),
      ),
      child: Row(
        children: [
          Icon(
            attached ? Icons.description_outlined : Icons.upload_file_outlined,
            color: attached ? _warnaPrimer : _warnaTeksRedup,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: attached ? _warnaPrimerGelap : _warnaTeksRedup,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubmissionCard extends StatelessWidget {
  const SubmissionCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final jenis = item['jenis']?.toString() ?? '-';
    final status = item['status']?.toString() ?? 'menunggu';
    final mulai = item['tanggal_mulai']?.toString() ?? '-';
    final selesai = item['tanggal_selesai']?.toString() ?? '-';
    final alasan = item['alasan']?.toString() ?? '-';

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: status),
              Text(
                statusLabel(jenis),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _warnaTeksUtama,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.date_range_outlined,
                size: 16,
                color: _warnaTeksRedup,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$mulai s/d $selesai',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _warnaTeksRedup,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alasan, style: const TextStyle(height: 1.35)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _warnaBiru.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(_radiusKartu),
            ),
            child: Icon(icon, color: _warnaBiru),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _warnaTeksUtama,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _warnaTeksRedup, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);
    final content = _HistorySummary(item: item);
    final chip = StatusChip(status: item['status']?.toString() ?? '');

    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: compact ? 76 : 54,
            decoration: BoxDecoration(
              color: statusColor(item['status']?.toString() ?? ''),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [content, const SizedBox(height: 10), chip],
                  )
                : Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 8),
                      chip,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileHero extends StatelessWidget {
  const ProfileHero({super.key, required this.user, required this.teacher});

  final Map<String, dynamic> user;
  final Map<String, dynamic> teacher;

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);
    final nama = user['nama']?.toString() ?? 'Guru';
    final email = user['email']?.toString() ?? '-';
    final mapel = teacher['mata_pelajaran']?.toString() ?? 'Mata pelajaran';

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radiusKartu),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_warnaBiru, _warnaPrimer],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 52 : 58,
            height: compact ? 52 : 58,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            clipBehavior: Clip.antiAlias,
            child: const Image(
              image: AssetImage(_assetAvatarPlaceholder),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    fontSize: compact ? 19 : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mapel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['tanggal']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatIsoTime(item['jam_masuk_pada']?.toString())} - ${formatIsoTime(item['jam_pulang_pada']?.toString())}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _warnaTeksRedup),
        ),
      ],
    );
  }
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  final String baseUrl;
  final String? token;
  final HttpClient _httpClient = HttpClient();

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(method, _uri(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode >= 400) throw ApiException.fromPayload(payload);
    return payload;
  }

  Future<dynamic> multipartLeave(
    Map<String, String> fields,
    PickedDocument? document,
  ) async {
    final boundary = '----presensi-${DateTime.now().microsecondsSinceEpoch}';
    final bytes = BytesBuilder();

    for (final entry in fields.entries) {
      bytes.add(utf8.encode('--$boundary\r\n'));
      bytes.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
        ),
      );
      bytes.add(utf8.encode('${entry.value}\r\n'));
    }

    if (document != null) {
      bytes.add(utf8.encode('--$boundary\r\n'));
      bytes.add(
        utf8.encode(
          'Content-Disposition: form-data; name="dokumen"; filename="${document.name}"\r\n',
        ),
      );
      bytes.add(
        utf8.encode(
          'Content-Type: ${document.mimeType ?? 'application/octet-stream'}\r\n\r\n',
        ),
      );
      bytes.add(document.bytes);
      bytes.add(utf8.encode('\r\n'));
    }

    bytes.add(utf8.encode('--$boundary--\r\n'));
    final body = bytes.takeBytes();
    final request = await _httpClient.postUrl(_uri('/pengajuan-izin'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.headers.contentType = ContentType(
      'multipart',
      'form-data',
      parameters: {'boundary': boundary},
    );
    request.contentLength = body.length;
    request.add(body);

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode >= 400) throw ApiException.fromPayload(payload);
    return payload;
  }

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  factory ApiException.fromPayload(dynamic payload) {
    if (payload is Map) {
      final errors = payload['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(first.first.toString());
        }
      }
      return ApiException(
        payload['pesan']?.toString() ??
            payload['message']?.toString() ??
            'Permintaan gagal.',
      );
    }
    return ApiException('Permintaan gagal.');
  }

  @override
  String toString() => message;
}

class PlatformBridge {
  static const _channel = MethodChannel('presensi/device');

  static Future<Map<String, dynamic>> deviceInfo() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'deviceInfo',
    );
    return Map<String, dynamic>.from(raw ?? {});
  }

  static Future<LocationSnapshot> location() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getLocation',
    );
    return LocationSnapshot.fromMap(Map<String, dynamic>.from(raw ?? {}));
  }

  static Future<void> saveValue(String key, String value) async {
    await _channel.invokeMethod('saveValue', {'key': key, 'value': value});
  }

  static Future<String?> readValue(String key) async {
    return _channel.invokeMethod<String>('readValue', {'key': key});
  }

  static Future<void> clearValue(String key) async {
    await _channel.invokeMethod('clearValue', {'key': key});
  }

  static Future<PickedDocument?> pickDocument() async {
    final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'pickDocument',
    );
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw);
    return PickedDocument(
      name: map['name']?.toString() ?? 'dokumen',
      mimeType: map['mime_type']?.toString(),
      bytes: map['bytes'] as Uint8List,
    );
  }
}

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.mockedLocation,
  });

  factory LocationSnapshot.fromMap(Map<String, dynamic> map) {
    return LocationSnapshot(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      mockedLocation: map['mocked_location'] == true,
    );
  }

  final double latitude;
  final double longitude;
  final int accuracy;
  final bool mockedLocation;
}

class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final String? mimeType;
  final Uint8List bytes;
}

const double _batasLayarXxs = 360;

bool layarXxs(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _batasLayarXxs;

EdgeInsets paddingHalaman(BuildContext context) {
  return EdgeInsets.all(layarXxs(context) ? 12 : 16);
}

class ResponsivePair extends StatelessWidget {
  const ResponsivePair({
    super.key,
    required this.first,
    required this.second,
    this.gap = 12,
    this.stretchNarrow = false,
  });

  final Widget first;
  final Widget second;
  final double gap;
  final bool stretchNarrow;

  @override
  Widget build(BuildContext context) {
    if (layarXxs(context)) {
      return Column(
        crossAxisAlignment: stretchNarrow
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: [
          first,
          SizedBox(height: gap),
          second,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: first),
        SizedBox(width: gap),
        Expanded(child: second),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor = _warnaPanel,
    this.borderColor = _warnaGaris,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(layarXxs(context) ? 12 : 16),
        child: child,
      ),
    );
  }
}

class LabeledValue extends StatelessWidget {
  const LabeledValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _warnaTeksRedup),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final compact = layarXxs(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(_radiusKartu),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFF991B1B)),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }
}

enum TipeNotifikasi { sukses, gagal, info }

void tampilkanNotifikasi(
  BuildContext context,
  String pesan, {
  TipeNotifikasi tipe = TipeNotifikasi.sukses,
}) {
  final warna = switch (tipe) {
    TipeNotifikasi.sukses => const Color(0xFF047857),
    TipeNotifikasi.gagal => const Color(0xFFB91C1C),
    TipeNotifikasi.info => const Color(0xFF0369A1),
  };
  final ikon = switch (tipe) {
    TipeNotifikasi.sukses => Icons.check_circle_outline,
    TipeNotifikasi.gagal => Icons.error_outline,
    TipeNotifikasi.info => Icons.info_outline,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: warna,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(ikon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan)),
          ],
        ),
      ),
    );
}

Future<bool> konfirmasiTindakan(
  BuildContext context, {
  required String judul,
  required String pesan,
  required String labelSetuju,
  required IconData ikon,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: Icon(ikon, color: _warnaPrimerGelap),
            title: Text(judul),
            content: Text(pesan),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(labelSetuju),
              ),
            ],
          );
        },
      ) ??
      false;
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.onDark = false});

  final String status;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.16)
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.20))
            : null,
      ),
      child: Text(
        statusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onDark ? Colors.white : color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

Color statusColor(String status) {
  return switch (status) {
    'hadir' => const Color(0xFF047857),
    'terlambat' => const Color(0xFFB45309),
    'menunggu' => const Color(0xFF475569),
    'disetujui' => const Color(0xFF047857),
    'ditolak' => const Color(0xFFB91C1C),
    'izin' || 'sakit' || 'cuti' => const Color(0xFF0369A1),
    'alpha' => const Color(0xFFB91C1C),
    _ => _warnaTeksRedup,
  };
}

String statusLabel(String status) {
  return switch (status) {
    'hadir' => 'Tepat Waktu',
    'terlambat' => 'Terlambat',
    'izin' => 'Izin',
    'sakit' => 'Sakit',
    'cuti' => 'Cuti',
    'alpha' => 'Alpha',
    'menunggu' => 'Menunggu',
    'disetujui' => 'Disetujui',
    'ditolak' => 'Ditolak',
    'belum_presensi' => 'Belum Presensi',
    _ => status,
  };
}

String formatIsoTime(String? value) {
  if (value == null || value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '-';
  return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

String dateOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String monthOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
}

String formatTanggalLengkap(DateTime value) {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  return '${hari[value.weekday - 1]}, ${value.day} ${bulan[value.month - 1]} ${value.year}';
}

String formatTanggalPendek(DateTime value) {
  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day} ${bulan[value.month - 1]} ${value.year}';
}

String inisialNama(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'G';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

int haversineMeters(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  const earthRadius = 6371000.0;
  final latDelta = _radians(toLat - fromLat);
  final lngDelta = _radians(toLng - fromLng);
  final a =
      pow(sin(latDelta / 2), 2) +
      cos(_radians(fromLat)) * cos(_radians(toLat)) * pow(sin(lngDelta / 2), 2);
  return (earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))).round();
}

double _radians(double value) => value * pi / 180;
