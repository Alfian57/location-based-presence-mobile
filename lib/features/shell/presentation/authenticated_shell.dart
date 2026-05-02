part of '../../../main.dart';

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
