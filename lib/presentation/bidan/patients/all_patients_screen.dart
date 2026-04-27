import 'package:bundadini/domain/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/examination_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/empty_state.dart';

class AllPatientsScreen extends StatefulWidget {
  const AllPatientsScreen({super.key});
  @override
  State<AllPatientsScreen> createState() => _AllPatientsScreenState();
}

class _AllPatientsScreenState extends State<AllPatientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _filterStatus; // null = semua

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bidanId = context.read<AuthProvider>().currentUser?.id ?? '';
      context.read<PatientProvider>().loadAll(bidanId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PatientModel> _filtered(List<PatientModel> all) {
    var result = all;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((p) => p.nama.toLowerCase().contains(q) || p.nik.contains(q))
          .toList();
    }
    if (_filterStatus != null) {
      result = result.where((p) => p.status.value == _filterStatus).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final patProv = context.watch<PatientProvider>();
    final list = _filtered(patProv.patients);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.semuaPasien)),
      body: Column(children: [
        // Search + Filter bar
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: AppStrings.cariPasien,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _FilterChip('Semua', null, _filterStatus,
                    () => setState(() => _filterStatus = null)),
                const SizedBox(width: 8),
                _FilterChip('Aktif', 'aktif', _filterStatus,
                    () => setState(() => _filterStatus = 'aktif')),
                const SizedBox(width: 8),
                const SizedBox(width: 8),
                _FilterChip('Selesai', 'selesai', _filterStatus,
                    () => setState(() => _filterStatus = 'selesai')),
              ]),
            ),
          ]),
        ),

        // List─
        Expanded(
          child: patProv.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : list.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: _query.isEmpty
                          ? AppStrings.pasienKosong
                          : 'Tidak ada hasil untuk "$_query"')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        final bidanId =
                            context.read<AuthProvider>().currentUser?.id ?? '';
                        context.read<PatientProvider>().loadAll(bidanId);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            _PatientBidanCard(patient: list[i]),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.primary : Colors.white,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}

class _PatientBidanCard extends StatelessWidget {
  final PatientModel patient;
  const _PatientBidanCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.read<PatientProvider>().loadPatient(patient.id);
          context.read<ExaminationProvider>().loadHistory(patient.id);
          // Navigate ke detail pasien (bidan view)
          context.push('/bidan/patients/${patient.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: patient.fotoUrl.isNotEmpty
                  ? Image.network(patient.fotoUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatar())
                  : _avatar(),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(patient.nama,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('NIK: ${patient.nik}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecond)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppColors.textSecond),
                    const SizedBox(width: 4),
                    Text('HPHT: ${DateFormatter.toDisplay(patient.hpht)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecond)),
                  ]),
                ])),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatusDot(patient.status),
              const SizedBox(height: 4),
              Text(patient.status.label,
                  style: TextStyle(
                      fontSize: 11, color: _statusColor(patient.status))),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecond, size: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _avatar() => Container(
      width: 56,
      height: 56,
      color: AppColors.redPale,
      child:
          const Icon(Icons.person_rounded, color: AppColors.primary, size: 32));

  Color _statusColor(StatusPasien s) {
    switch (s) {
      case StatusPasien.aktif:
        return AppColors.success;
      case StatusPasien.pindah:
        return AppColors.warning;
      case StatusPasien.selesai:
        return AppColors.textSecond;
    }
  }
}

class _StatusDot extends StatelessWidget {
  final StatusPasien status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    final color = status == StatusPasien.aktif
        ? AppColors.success
        : status == StatusPasien.pindah
            ? AppColors.warning
            : AppColors.textSecond;
    return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
