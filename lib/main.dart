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

void main() {
  runApp(const PresensiApp());
}

class PresensiApp extends StatefulWidget {
  const PresensiApp({super.key});

  @override
  State<PresensiApp> createState() => _PresensiAppState();
}

class _PresensiAppState extends State<PresensiApp> {
  String _apiBase = _defaultApiBase;
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
    final storedBase = await PlatformBridge.readValue('api_base');
    final storedToken = await PlatformBridge.readValue('token');
    _apiBase = storedBase?.isNotEmpty == true ? storedBase! : _defaultApiBase;
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

  Future<void> _authenticate(
    String token,
    Map<String, dynamic> user,
    String apiBase,
  ) async {
    await PlatformBridge.saveValue('token', token);
    await PlatformBridge.saveValue('api_base', apiBase);
    setState(() {
      _token = token;
      _user = user;
      _apiBase = apiBase;
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          isDense: true,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: Color(0xFFE2E8F0)),
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.apiBase,
    required this.onAuthenticated,
  });

  final String apiBase;
  final Future<void> Function(
    String token,
    Map<String, dynamic> user,
    String apiBase,
  )
  onAuthenticated;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _apiBase = TextEditingController(
    text: widget.apiBase,
  );
  final _email = TextEditingController(text: 'guru@presensi.test');
  final _password = TextEditingController(text: 'password');
  bool _activationMode = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final device = await PlatformBridge.deviceInfo();
      final client = ApiClient(baseUrl: _apiBase.text.trim());
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
        _apiBase.text.trim(),
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
      final client = ApiClient(baseUrl: _apiBase.text.trim());
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Presensi Guru',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activationMode
                            ? 'Aktivasi akun dari admin sekolah'
                            : 'Masuk akun guru',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        ErrorBox(message: _error!),
                      ],
                      const SizedBox(height: 18),
                      TextField(
                        controller: _apiBase,
                        decoration: const InputDecoration(labelText: 'URL API'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi',
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
                            : const Icon(Icons.login),
                        label: Text(
                          _activationMode ? 'Aktivasi & Masuk' : 'Masuk',
                        ),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(
                                () => _activationMode = !_activationMode,
                              ),
                        child: Text(
                          _activationMode
                              ? 'Kembali ke Masuk'
                              : 'Aktivasi Akun',
                        ),
                      ),
                      TextButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: const Text('Reset Kata Sandi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Guru'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Presensi Hari Ini',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      status:
                          (_attendance?['status'] as String?) ??
                          'belum_presensi',
                    ),
                    const Spacer(),
                    if (_loading)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LabeledValue(
                        label: 'Presensi Masuk',
                        value: formatIsoTime(
                          _attendance?['jam_masuk_pada'] as String?,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: 'Presensi Pulang',
                        value: formatIsoTime(
                          _attendance?['jam_pulang_pada'] as String?,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LabeledValue(
                        label: 'Jadwal Kerja',
                        value: shift?['nama']?.toString() ?? '-',
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: 'Jam Kerja',
                        value: shift == null
                            ? '-'
                            : '${shift['jam_masuk']} - ${shift['jam_pulang']}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lokasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                LabeledValue(
                  label: 'Sekolah',
                  value: school?['nama']?.toString() ?? '-',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LabeledValue(
                        label: 'Akurasi GPS',
                        value: _location == null
                            ? '-'
                            : '${_location!.accuracy} m',
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: 'Jarak',
                        value: distance == null ? '-' : '$distance m',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LabeledValue(
                        label: 'Lokasi Palsu',
                        value: _location?.mockedLocation == true
                            ? 'Terdeteksi'
                            : 'Tidak',
                      ),
                    ),
                    Expanded(
                      child: LabeledValue(
                        label: 'Radius',
                        value: school == null
                            ? '-'
                            : '${school['radius_meter']} m',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _clocking ? null : () => _clock('masuk'),
                  icon: const Icon(Icons.login),
                  label: const Text('Presensi Masuk'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clocking ? null : () => _clock('pulang'),
                  icon: const Icon(Icons.logout),
                  label: const Text('Presensi Pulang'),
                ),
              ),
            ],
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

  Future<void> _load() async {
    setState(() => _loading = true);
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Izin, Sakit, Cuti',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Pengajuan',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'izin', child: Text('Izin')),
                    DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                    DropdownMenuItem(value: 'cuti', child: Text('Cuti')),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? 'izin'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _start,
                        readOnly: true,
                        onTap: () => _pickDate(_start),
                        decoration: const InputDecoration(labelText: 'Mulai'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _end,
                        readOnly: true,
                        onTap: () => _pickDate(_end),
                        decoration: const InputDecoration(labelText: 'Selesai'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Alasan'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _document?.name ?? 'Belum ada dokumen',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Dokumen'),
                    ),
                  ],
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
          Text(
            'Status Pengajuan',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ..._items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(status: item['status'] as String),
                          const SizedBox(width: 8),
                          Text(
                            statusLabel(item['jenis'] as String),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item['tanggal_mulai']} s/d ${item['tanggal_selesai']}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Text(item['alasan'] as String),
                    ],
                  ),
                ),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Riwayat Presensi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _month,
                  decoration: const InputDecoration(labelText: 'Bulan YYYY-MM'),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _load, child: const Text('Filter')),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(message: _error!),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_items.isEmpty)
            const Panel(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Belum ada riwayat.'),
                ),
              ),
            )
          else
            ..._items.map((raw) {
              final item = Map<String, dynamic>.from(raw as Map);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['tanggal'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatIsoTime(item['jam_masuk_pada'] as String?)} - ${formatIsoTime(item['jam_pulang_pada'] as String?)}',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(status: item['status'] as String),
                    ],
                  ),
                ),
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Profil',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledValue(
                label: 'Nama',
                value: widget.user['nama']?.toString() ?? '-',
              ),
              const SizedBox(height: 10),
              LabeledValue(
                label: 'Email',
                value: widget.user['email']?.toString() ?? '-',
              ),
              const SizedBox(height: 10),
              LabeledValue(
                label: 'NIP',
                value:
                    teacher['nip']?.toString() ??
                    widget.user['nomor_pegawai']?.toString() ??
                    '-',
              ),
              const SizedBox(height: 10),
              LabeledValue(
                label: 'Mata Pelajaran',
                value: teacher['mata_pelajaran']?.toString() ?? '-',
              ),
              const SizedBox(height: 10),
              LabeledValue(
                label: 'Jadwal',
                value: teacher['jadwal_kerja']?.toString() ?? '-',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notifikasi'),
                value: teacher['notifikasi_aktif'] == true,
                onChanged: _saving ? null : _setNotifications,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: widget.onLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
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

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFF991B1B)),
          const SizedBox(width: 8),
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

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'hadir' => const Color(0xFF047857),
      'terlambat' => const Color(0xFFB45309),
      'menunggu' => const Color(0xFF475569),
      'disetujui' => const Color(0xFF047857),
      'ditolak' => const Color(0xFFB91C1C),
      'izin' || 'sakit' || 'cuti' => const Color(0xFF0369A1),
      _ => const Color(0xFF64748B),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
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
