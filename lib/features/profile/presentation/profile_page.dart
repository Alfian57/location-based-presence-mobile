part of '../../../main.dart';

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

  ProfileRepository get _repository => ProfileRepository(widget.client);

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
    if (value) {
      final allowed = await PlatformBridge.requestNotificationPermission();
      if (!allowed) {
        if (!mounted) return;
        tampilkanNotifikasi(
          context,
          'Izin notifikasi belum diberikan di perangkat.',
          tipe: TipeNotifikasi.gagal,
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final user = await _repository.updateNotifications(value);
      widget.onUserChanged(user);
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
