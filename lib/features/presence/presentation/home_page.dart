part of '../../../main.dart';

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

  PresenceRepository get _repository => PresenceRepository(widget.client);

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
      final today = await _repository.today();
      final shift = await _repository.workSchedule();
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
      final result = await _repository.clock(type);
      final location = result['location'] as LocationSnapshot;
      setState(() {
        _attendance = result['attendance'] as Map<String, dynamic>;
        _location = location;
      });
      if (!mounted) return;
      tampilkanNotifikasi(context, result['message'] as String);
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
