part of '../../main.dart';

const double _batasLayarXxs = 360;
const double _batasPasanganVertikal = 430;

bool layarXxs(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _batasLayarXxs;

bool layarPasanganVertikal(BuildContext context) =>
    MediaQuery.sizeOf(context).width <= _batasPasanganVertikal;

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
    if (layarPasanganVertikal(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(labelSetuju),
                    ),
                  ),
                ],
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

String normalisasiBaseApiMobile(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return _fallbackApiBase;

  final uri = Uri.parse(trimmed);
  final segments = uri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  final mobileApiIndex = _indexSegmenApiMobile(segments);

  final List<String> normalizedSegments;
  if (mobileApiIndex >= 0) {
    normalizedSegments = segments.take(mobileApiIndex + 2).toList();
  } else if (segments.isNotEmpty && segments.last == 'api') {
    normalizedSegments = [...segments, 'mobile'];
  } else {
    normalizedSegments = [...segments, 'api', 'mobile'];
  }

  final normalized = uri.replace(
    pathSegments: normalizedSegments,
    query: null,
    fragment: null,
  );
  return normalized.toString().replaceFirst(RegExp(r'/$'), '');
}

String apiBaseDariEnv() {
  return normalisasiBaseApiMobile(
    dotenv.env[_apiBaseEnvKey] ?? _fallbackApiBase,
  );
}

int _indexSegmenApiMobile(List<String> segments) {
  for (var index = 0; index < segments.length - 1; index++) {
    if (segments[index] == 'api' && segments[index + 1] == 'mobile') {
      return index;
    }
  }
  return -1;
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
