part of '../../../main.dart';

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

  LeaveRepository get _repository => LeaveRepository(widget.client);

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
      final items = await _repository.list();
      setState(() => _items = items);
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
    if (document == null) return;
    if (!document.validForLeaveUpload) {
      if (!mounted) return;
      tampilkanNotifikasi(
        context,
        'Dokumen harus berupa PDF, JPG, JPEG, atau PNG maksimal 4 MB.',
        tipe: TipeNotifikasi.gagal,
      );
      return;
    }
    setState(() => _document = document);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.submit(
        type: _type,
        startDate: _start.text,
        endDate: _end.text,
        reason: _reason.text,
        document: _document,
      );
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
                SizedBox(
                  height: 132,
                  child: TextField(
                    controller: _reason,
                    minLines: null,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: const InputDecoration(
                      hintText: 'Alasan',
                      prefixIcon: Icon(Icons.notes_outlined),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
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
