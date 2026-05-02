part of '../../main.dart';

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
    final foregroundColor = attached ? _warnaPrimerGelap : _warnaTeksRedup;

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
        mainAxisAlignment: attached
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            attached ? Icons.description_outlined : Icons.upload_file_outlined,
            color: attached ? _warnaPrimer : foregroundColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              textAlign: attached ? TextAlign.start : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
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
