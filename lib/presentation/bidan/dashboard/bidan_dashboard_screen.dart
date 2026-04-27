import 'package:bundadini/data/models/examination_model.dart';
import 'package:bundadini/domain/providers/connectivity_provider.dart';
import 'package:bundadini/presentation/_widgets/offline_banner.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/examination_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/konfirmasi_dialog.dart';
import '../../_widgets/section_header.dart';

class BidanDashboardScreen extends StatefulWidget {
  const BidanDashboardScreen({super.key});
  @override
  State<BidanDashboardScreen> createState() => _BidanDashboardScreenState();
}

class _BidanDashboardScreenState extends State<BidanDashboardScreen> {
  final _examRepo = ExaminationRepository();
  final _authRepo = AuthRepository();

  int _pemeriksaanBulanIni = 0;
  int _ibuRisikoTinggi = 0;
  int _kaderAktif = 0;
  Map<int, int> _chartData = {}; // bulan -> jumlah pemeriksaan
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final bidanId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (bidanId.isEmpty) return;
    context.read<PatientProvider>().clear();
    await Future.wait([
      context.read<PatientProvider>().loadAll(bidanId).catchError((e) {
        debugPrint('Error load patients: $e');
      }),
      _loadStats(),
    ]);
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);

    try {
      final auth = context.read<AuthProvider>();
      final bidanId = auth.currentUser?.id ?? '';

      print('==============================');
      print('📊 START LOAD STATS');
      print('👤 bidanId: $bidanId');

      if (bidanId.isEmpty) {
        print('❌ bidanId kosong, abort load stats');
        return;
      }

      // 1. Pemeriksaan bulan ini
      _pemeriksaanBulanIni = await _examRepo.countThisMonth(bidanId);

      print('🧪 Pemeriksaan bulan ini: $_pemeriksaanBulanIni');

      // 2. Kader aktif
      final kaders = await _authRepo.fetchKaders(bidanId);
      _kaderAktif = kaders.where((k) => k.isActive).length;

      print('👩‍⚕️ Total kader: ${kaders.length}');
      print('✅ Kader aktif: $_kaderAktif');

      // 3. Chart 6 bulan terakhir
      final now = DateTime.now();
      _chartData = {};

      print('📈 Loading chart data...');

      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        print('➡️ Month range: $month - $nextMonth');

        final exams = await _examRepo.fetchByDateRange(
          month,
          nextMonth,
          bidanId,
        );

        _chartData[now.month - i] = exams.length;

        print('📊 Month ${month.month}: ${exams.length} exams');
      }

      // 4. Risiko tinggi
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthEnd = DateTime(now.year, now.month + 1, 1);

      print('⚠️ Loading risk data...');

      final thisMonthExams = await _examRepo.fetchByDateRange(
        thisMonthStart,
        thisMonthEnd,
        bidanId,
      );

      print('📦 Total exams this month: ${thisMonthExams.length}');

      final risikoPatients = <String>{};

      for (final exam in thisMonthExams) {
        final ibuBahaya = exam.statusIbu == ExaminationStatus.risikoTinggi;

        final janinBahaya = exam.statusJanin == JaninStatus.djjRendah ||
            exam.statusJanin == JaninStatus.djjTinggi;

        if (ibuBahaya || janinBahaya) {
          risikoPatients.add(exam.patientId);
        }
      }

      _ibuRisikoTinggi = risikoPatients.length;

      print('🚨 Ibu risiko tinggi: $_ibuRisikoTinggi');
      print('==============================');
      print('✅ STATS LOADED SUCCESS');
    } catch (e, stack) {
      print('❌ ERROR LOAD STATS: $e');
      print('STACKTRACE: $stack');
    } finally {
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  Future<void> _logout() async {
    final ok = await KonfirmasiDialog.show(context,
        title: 'Keluar',
        message: AppStrings.logoutConfirm,
        labelYa: 'Keluar',
        isDangerous: true);
    if (ok && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 3 : 2),
        margin: const EdgeInsets.only(
          bottom: 20,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patProv = context.watch<PatientProvider>();
    final nama = auth.currentUser?.nama ?? 'Bidan';

    final allPatients = patProv.patients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Keluar',
              onPressed: _logout),
        ],
      ),
      body: Consumer<ConnectivityProvider>(
        builder: (_, connectivity, child) => OfflineBanner(
          isOffline: connectivity.isOffline,
          child: child!,
        ),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sapaan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Selamat datang,',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(nama,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(DateFormatter.toDisplayWithDay(DateTime.now()),
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13)),
                          ]),
                      const Spacer(),
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.medical_services_rounded,
                              color: Colors.white, size: 28)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Stats cards
                  const SectionHeader(title: 'Ringkasan Data'),
                  const SizedBox(height: 12),
                  _loadingStats
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      : _StatsGrid(
                          totalIbu: allPatients.length,
                          pemeriksaanBulanIni: _pemeriksaanBulanIni,
                          ibuRisikoTinggi: _ibuRisikoTinggi,
                          kaderAktif: _kaderAktif,
                        ),
                  const SizedBox(height: 16),

                  // Bar Chart 6 bulan
                  const SectionHeader(title: AppStrings.statistik6Bulan),
                  const SizedBox(height: 12),
                  _loadingStats
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      : _BarChartCard(chartData: _chartData),
                  const SizedBox(height: 16),

                  // Menu Grid
                  const SectionHeader(title: 'Menu'),
                  const SizedBox(height: 12),
                  _MenuGrid(
                    showSnackbar: _showSnackbar,
                    onRefresh: _load,
                  ),
                  const SizedBox(height: 24),
                ]),
          ),
        ),
      ),
    );
  }
}

// Stats Grid
class _StatsGrid extends StatelessWidget {
  final int totalIbu;
  final int pemeriksaanBulanIni;
  final int ibuRisikoTinggi;
  final int kaderAktif;

  const _StatsGrid({
    required this.totalIbu,
    required this.pemeriksaanBulanIni,
    required this.ibuRisikoTinggi,
    required this.kaderAktif,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _StatCard(AppStrings.totalIbu, '$totalIbu',
            Icons.pregnant_woman_rounded, AppColors.primary),
        _StatCard(AppStrings.pemeriksaanBulanIni, '$pemeriksaanBulanIni',
            Icons.assignment_rounded, AppColors.info),
        _StatCard(AppStrings.ibuRisikoTinggi, '$ibuRisikoTinggi',
            Icons.warning_amber_rounded, AppColors.danger),
        _StatCard(AppStrings.kaderAktif, '$kaderAktif', Icons.people_rounded,
            AppColors.success),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecond),
                    maxLines: 2),
              ])),
        ]),
      ),
    );
  }
}

// Bar Chart 6 bulan
class _BarChartCard extends StatelessWidget {
  final Map<int, int> chartData;

  const _BarChartCard({required this.chartData});

  List<String> _getLastSixMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      return DateFormatter.toMonthYear(m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = _getLastSixMonths();
    final now = DateTime.now();

    // Konversi chartData ke list dengan urutan yang benar
    final data = List.generate(6, (i) {
      final monthKey = now.month - (5 - i);
      return (chartData[monthKey] ?? 0).toDouble();
    });

    final maxValue = data.isEmpty ? 10.0 : data.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Jumlah Pemeriksaan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: data.every((e) => e == 0)
                ? const Center(
                    child: Text(
                      'Belum ada data pemeriksaan',
                      style: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 14,
                      ),
                    ),
                  )
                : BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue + 3,
                    barGroups: List.generate(
                        6,
                        (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: data[i] == 0
                                      ? 0.1
                                      : data[i], // Minimal 0.1 untuk visibility
                                  width: 20,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryLight,
                                        AppColors.primary
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter),
                                )
                              ],
                            )),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecond)))),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= months.length) {
                                  return const SizedBox.shrink();
                                }
                                final parts = months[idx].split(' ');
                                return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(parts[0],
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecond)),
                                    ]);
                              })),
                    ),
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.divider, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.primary,
                        getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                          '${rod.toY.toInt()} pemeriksaan',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )),
          ),
        ]),
      ),
    );
  }
}

// Menu Grid
class _MenuGrid extends StatelessWidget {
  final Function(String, {required bool isError}) showSnackbar;
  final VoidCallback onRefresh;

  const _MenuGrid({
    required this.showSnackbar,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final menus = [
      _MenuItem(
          AppStrings.kelolaKader,
          Icons.people_alt_rounded,
          AppColors.info,
          () => context.push(AppRoutes.kaderList).then((_) => onRefresh())),
      _MenuItem(
          AppStrings.semuaPasien,
          Icons.pregnant_woman_rounded,
          AppColors.primary,
          () => context.push(AppRoutes.allPatients).then((_) => onRefresh())),
      _MenuItem(
          AppStrings.exportExcel,
          Icons.table_chart_rounded,
          AppColors.success,
          () => context.push(AppRoutes.exportScreen).then((_) => onRefresh())),
      _MenuItem(AppStrings.profilBidan, Icons.person_rounded, AppColors.warning,
          () => _showEditProfil(context)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: menus.map((m) => _MenuCard(m)).toList(),
    );
  }

  void _showEditProfil(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final puskCtrl =
        TextEditingController(text: auth.currentUser?.namaPuskesmas ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Profil Bidan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: puskCtrl,
                decoration: const InputDecoration(
                    labelText: AppStrings.namaPuskesmasLabel,
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final newName = puskCtrl.text.trim();

                  if (newName.isEmpty) {
                    showSnackbar(
                      'Nama puskesmas tidak boleh kosong',
                      isError: true,
                    );
                    return;
                  }

                  try {
                    await auth.updateProfile({'namaPuskesmas': newName});

                    if (ctx.mounted) Navigator.pop(ctx);

                    if (context.mounted) {
                      showSnackbar(
                        'Profil berhasil diperbarui',
                        isError: false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showSnackbar(
                        'Gagal memperbarui profil: $e',
                        isError: true,
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.label, this.icon, this.color, this.onTap);
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard(this.item);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(item.icon, color: item.color, size: 28)),
            const SizedBox(height: 10),
            Text(item.label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2),
          ]),
        ),
      ),
    );
  }
}
