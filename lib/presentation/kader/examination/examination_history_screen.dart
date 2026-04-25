import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/examination_model.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/empty_state.dart';
import '../../_widgets/section_header.dart';
import '../../_widgets/status_badge.dart';

class ExaminationHistoryScreen extends StatefulWidget {
  final String patientId;
  const ExaminationHistoryScreen({super.key, required this.patientId});
  @override
  State<ExaminationHistoryScreen> createState() =>
      _ExaminationHistoryScreenState();
}

class _ExaminationHistoryScreenState extends State<ExaminationHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ExaminationProvider>().loadHistory(widget.patientId));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = context.watch<ExaminationProvider>();
    final patient = context.watch<PatientProvider>().selectedPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
            patient != null
                ? 'Riwayat — ${patient.nama}'
                : AppStrings.riwayatPemeriksaan,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Riwayat'), Tab(text: 'Grafik Tren')],
        ),
      ),
      body: exam.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(controller: _tab, children: [
              _RiwayatList(history: exam.history),
              _GrafikTab(exam: exam),
            ]),
    );
  }
}

// Tab Riwayat
class _RiwayatList extends StatelessWidget {
  final List<ExaminationModel> history;
  const _RiwayatList({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyState(
          icon: Icons.assignment_outlined,
          title: 'Belum ada riwayat pemeriksaan');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (ctx, i) => _HistoryCard(exam: history[i]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ExaminationModel exam;
  const _HistoryCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/shared/examine/result', extra: exam.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 15, color: AppColors.textSecond),
              const SizedBox(width: 6),
              Text(DateFormatter.toDisplay(exam.tanggal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(width: 10),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.redPale,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${exam.usiaKehamilan} minggu',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600))),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecond, size: 20),
            ]),
            const SizedBox(height: 6),
            Text('Kader: ${exam.kaderNama}',
                style:
                    const TextStyle(color: AppColors.textSecond, fontSize: 13)),
            const SizedBox(height: 10),
            Row(children: [
              _MiniStat('💓', '${exam.sistolik}/${exam.diastolik}', 'mmHg'),
              const SizedBox(width: 16),
              _MiniStat(
                '⚖️',
                exam.beratBadan.toStringAsFixed(1),
                'kg',
              ),
              const SizedBox(width: 16),
              _MiniStat('🫀', '${exam.djj}', 'bpm'),
              const Spacer(),
              StatusBadge(status: exam.statusIbu),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji, value, unit;
  const _MiniStat(this.emoji, this.value, this.unit);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(width: 2),
      Text(unit,
          style: const TextStyle(color: AppColors.textSecond, fontSize: 12)),
    ]);
  }
}

// Tab Grafik─
class _GrafikTab extends StatefulWidget {
  final ExaminationProvider exam;
  const _GrafikTab({required this.exam});
  @override
  State<_GrafikTab> createState() => _GrafikTabState();
}

class _GrafikTabState extends State<_GrafikTab> {
  int _selectedChart = 0; // 0=BB, 1=Tensi, 2=DJJ

  @override
  Widget build(BuildContext context) {
    if (widget.exam.history.length < 2) {
      return const EmptyState(
        icon: Icons.show_chart_rounded,
        title: 'Minimal 2 pemeriksaan untuk grafik',
        subtitle: 'Lakukan pemeriksaan berikutnya untuk melihat tren',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Pilih grafik
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _ChipBtn('Berat Badan', 0, _selectedChart,
                () => setState(() => _selectedChart = 0)),
            const SizedBox(width: 8),
            _ChipBtn('Tekanan Darah', 1, _selectedChart,
                () => setState(() => _selectedChart = 1)),
            const SizedBox(width: 8),
            _ChipBtn('DJJ', 2, _selectedChart,
                () => setState(() => _selectedChart = 2)),
          ]),
        ),
        const SizedBox(height: 20),

        // Grafik aktif
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedChart == 0
              ? _BbChart(key: const ValueKey(0), history: widget.exam.history)
              : _selectedChart == 1
                  ? _TensiChart(
                      key: const ValueKey(1), history: widget.exam.history)
                  : _DjjChart(
                      key: const ValueKey(2), history: widget.exam.history),
        ),
        const SizedBox(height: 20),

        // Tabel ringkasan
        const SectionHeader(title: 'Ringkasan Data'),
        const SizedBox(height: 12),
        _SummaryTable(history: widget.exam.history),
      ]),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final int index, selected;
  final VoidCallback onTap;
  const _ChipBtn(this.label, this.index, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: active ? AppColors.primary : AppColors.divider)),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textPrimary,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                fontSize: 14)),
      ),
    );
  }
}

// Grafik BB
class _BbChart extends StatelessWidget {
  final List<ExaminationModel> history;
  const _BbChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed.toList();
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.beratBadan))
        .toList();
    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0, double.infinity)
        .toDouble();
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 5;

    return _ChartCard(
      title: AppStrings.grafikBb,
      unit: 'kg',
      color: AppColors.chartBlue,
      child: LineChart(LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: _titlesData(
            data.map((e) => DateFormatter.toShort(e.tanggal)).toList(), 'kg'),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.chartBlue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true, color: AppColors.chartBlue.withValues(alpha: 0.1)),
          )
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.primary,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} kg',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ))
                .toList(),
          ),
        ),
      )),
    );
  }
}

// Grafik Tensi─
class _TensiChart extends StatelessWidget {
  final List<ExaminationModel> history;
  const _TensiChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed.toList();
    final sisSpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.sistolik.toDouble()))
        .toList();
    final diaSpots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.diastolik.toDouble()))
        .toList();

    return _ChartCard(
      title: AppStrings.grafikTensi,
      unit: 'mmHg',
      color: AppColors.chartRed,
      legend: const [
        _LegendDot('Sistolik', AppColors.chartRed),
        SizedBox(width: 16),
        _LegendDot('Diastolik', AppColors.chartBlue)
      ],
      child: LineChart(LineChartData(
        minY: 40,
        maxY: 200,
        titlesData: _titlesData(
            data.map((e) => DateFormatter.toShort(e.tanggal)).toList(), 'mmHg'),
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.divider, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
              spots: sisSpots,
              isCurved: true,
              color: AppColors.chartRed,
              barWidth: 3,
              dotData: const FlDotData(show: true)),
          LineChartBarData(
              spots: diaSpots,
              isCurved: true,
              color: AppColors.chartBlue,
              barWidth: 3,
              dotData: const FlDotData(show: true)),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.primary,
            getTooltipItems: (spots) {
              final labels = ['Sis', 'Dia'];
              return spots
                  .asMap()
                  .entries
                  .map((e) => LineTooltipItem(
                        '${labels[e.key]}: ${e.value.y.toInt()} mmHg',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ))
                  .toList();
            },
          ),
        ),
      )),
    );
  }
}

// Grafik DJJ─
class _DjjChart extends StatelessWidget {
  final List<ExaminationModel> history;
  const _DjjChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final data = history.reversed.toList();
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.djj.toDouble()))
        .toList();

    return _ChartCard(
      title: AppStrings.grafikDjj,
      unit: 'bpm',
      color: AppColors.chartGreen,
      child: LineChart(LineChartData(
        minY: 80,
        maxY: 200,
        titlesData: _titlesData(
            data.map((e) => DateFormatter.toShort(e.tanggal)).toList(), 'bpm'),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) {
            if (v == 110 || v == 160) {
              return FlLine(
                  color: AppColors.danger.withValues(alpha: 0.5),
                  strokeWidth: 1.5,
                  dashArray: [6, 4]);
            }
            return const FlLine(color: AppColors.divider, strokeWidth: 1);
          },
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
              y: 110,
              color: AppColors.danger.withValues(alpha: 0.5),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => '110',
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 11))),
          HorizontalLine(
              y: 160,
              color: AppColors.danger.withValues(alpha: 0.5),
              strokeWidth: 1.5,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                  show: true,
                  labelResolver: (_) => '160',
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 11))),
        ]),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.chartGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true, color: AppColors.chartGreen.withValues(alpha: 0.1)),
          )
        ],
      )),
    );
  }
}

// ChartCard container
class _ChartCard extends StatelessWidget {
  final String title, unit;
  final Color color;
  final Widget child;
  final List<Widget>? legend;
  const _ChartCard(
      {required this.title,
      required this.unit,
      required this.color,
      required this.child,
      this.legend});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          if (legend != null) ...legend!,
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: child),
      ]),
    ));
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecond)),
    ]);
  }
}

// Shared chart titles─
FlTitlesData _titlesData(List<String> xLabels, String yUnit) {
  return FlTitlesData(
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    bottomTitles: AxisTitles(
        sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 32,
      getTitlesWidget: (v, meta) {
        final i = v.toInt();
        if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
        return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(xLabels[i],
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecond)));
      },
    )),
    leftTitles: AxisTitles(
        sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecond)),
    )),
  );
}

// Tabel ringkasan
class _SummaryTable extends StatelessWidget {
  final List<ExaminationModel> history;
  const _SummaryTable({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppColors.redPale),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 52,
        headingTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 13),
        dataTextStyle: const TextStyle(fontSize: 13),
        columns: const [
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Usia\n(mgg)')),
          DataColumn(label: Text('Tensi')),
          DataColumn(label: Text('BB\n(kg)')),
          DataColumn(label: Text('DJJ')),
          DataColumn(label: Text('Status Ibu')),
        ],
        rows: history
            .map((e) => DataRow(cells: [
                  DataCell(Text(DateFormatter.toShort(e.tanggal))),
                  DataCell(Text('${e.usiaKehamilan}')),
                  DataCell(Text('${e.sistolik}/${e.diastolik}')),
                  DataCell(Text(e.beratBadan.toStringAsFixed(1))),
                  DataCell(Text('${e.djj}')),
                  DataCell(StatusBadge(status: e.statusIbu)),
                ]))
            .toList(),
      ),
    ));
  }
}
