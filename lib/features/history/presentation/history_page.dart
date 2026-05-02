part of '../../../main.dart';

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

  HistoryRepository get _repository => HistoryRepository(widget.client);

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
      final items = await _repository.listByMonth(_month.text);
      setState(() => _items = items);
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
