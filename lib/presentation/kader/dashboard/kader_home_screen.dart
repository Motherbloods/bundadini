import 'package:bundadini/domain/providers/connectivity_provider.dart';
import 'package:bundadini/presentation/_widgets/network_image_fallback.dart';
import 'package:bundadini/presentation/_widgets/offline_banner.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/patient_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/patient_provider.dart';
import '../../_widgets/empty_state.dart';
import '../../_widgets/konfirmasi_dialog.dart';

class KaderHomeScreen extends StatefulWidget {
  const KaderHomeScreen({super.key});

  @override
  State<KaderHomeScreen> createState() => _KaderHomeScreenState();
}

class _KaderHomeScreenState extends State<KaderHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();

    if (auth.currentUser != null) {
      context.read<PatientProvider>().loadByKader(auth.currentUser!.id);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final ok = await KonfirmasiDialog.show(
      context,
      title: 'Keluar',
      message: AppStrings.logoutConfirm,
      labelYa: 'Keluar',
      isDangerous: true,
    );

    if (ok && mounted) {
      await context.read<AuthProvider>().logout();

      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final patient = context.watch<PatientProvider>();

    final nama = auth.currentUser?.nama ?? 'Kader';

    final listAktif = _query.isEmpty
        ? patient.patients
            .where((p) => p.status != StatusPasien.selesai)
            .toList()
        : patient.search(_query);

    final listSelesai = _query.isEmpty
        ? patient.patients
            .where((p) => p.status == StatusPasien.selesai)
            .toList()
        : [];

    final jumlahAktif =
        patient.patients.where((p) => p.status != StatusPasien.selesai).length;

    return GestureDetector(
      onTap: _hideKeyboard,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Keluar',
              onPressed: _logout,
            ),
          ],
        ),
        body: Consumer<ConnectivityProvider>(
          builder: (_, connectivity, child) => OfflineBanner(
            isOffline: connectivity.isOffline,
            child: child!,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $nama 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$jumlahAktif pasien aktif',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocusNode,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: AppStrings.cariPasien,
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                  _hideKeyboard();
                                },
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _load(),
                  child: CustomScrollView(
                    slivers: [
                      if (patient.isLoading)
                        const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (listAktif.isEmpty && listSelesai.isEmpty)
                        SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.pregnant_woman_rounded,
                            title: _query.isEmpty
                                ? AppStrings.pasienKosong
                                : 'Tidak ada pasien "$_query"',
                            subtitle: _query.isEmpty
                                ? 'Ketuk + untuk mendaftarkan pasien baru'
                                : null,
                          ),
                        )
                      else ...[
                        if (listAktif.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _PatientCard(patient: listAktif[i]),
                                childCount: listAktif.length,
                              ),
                            ),
                          ),
                        if (listSelesai.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.child_care_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sudah Melahirkan (${listSelesai.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              MediaQuery.of(context).padding.bottom + 16,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _PatientCard(
                                  patient: listSelesai[i],
                                  isSelesai: true,
                                ),
                                childCount: listSelesai.length,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push(AppRoutes.addPatient).then((_) => _load());
          },
          icon: const Icon(Icons.add),
          label: const Text(
            'Tambah Pasien',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final bool isSelesai;

  const _PatientCard({
    required this.patient,
    this.isSelesai = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isSelesai ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push('/kader/patients/${patient.id}');

            if (!context.mounted) return;

            final auth = context.read<AuthProvider>();
            final provider = context.read<PatientProvider>();

            await provider.loadByKader(auth.currentUser!.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: NetworkImageFallback(
                    url: patient.fotoUrl,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NIK: ${patient.nik}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        patient.hpht != null
                            ? 'HPHT: ${DateFormatter.toDisplay(patient.hpht!)}'
                            : 'HPHT: Belum diisi',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: patient.hpht != null
                                  ? null
                                  : AppColors.warning,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelesai)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '🎉 Melahirkan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecond,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
