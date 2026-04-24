import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../_widgets/empty_state.dart';
import '../../_widgets/konfirmasi_dialog.dart';

class KaderListScreen extends StatefulWidget {
  const KaderListScreen({super.key});
  @override
  State<KaderListScreen> createState() => _KaderListScreenState();
}

class _KaderListScreenState extends State<KaderListScreen> {
  final _repo = AuthRepository();
  List<UserModel> _kaders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final bidanId = context.read<AuthProvider>().currentUser?.id ?? '';
    _kaders = await _repo.fetchKaders(bidanId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _deactivate(UserModel kader) async {
    final ok = await KonfirmasiDialog.show(context,
        title: 'Nonaktifkan Kader',
        message:
            'Nonaktifkan ${kader.nama}? Kader tidak bisa login setelah ini.',
        labelYa: 'Nonaktifkan',
        isDangerous: true);
    if (ok) {
      await _repo.deactivateKader(kader.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.daftarKader)),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _kaders.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: AppStrings.kaderKosong,
                  subtitle: 'Ketuk + untuk mendaftarkan kader baru',
                  actionLabel: AppStrings.tambahKader,
                  onAction: () =>
                      context.push(AppRoutes.addKader).then((_) => _load()),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _kaders.length,
                    itemBuilder: (_, i) => _KaderCard(
                      kader: _kaders[i],
                      onDeactivate: () => _deactivate(_kaders[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addKader).then((_) => _load()),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text(AppStrings.tambahKader,
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _KaderCard extends StatelessWidget {
  final UserModel kader;
  final VoidCallback onDeactivate;
  const _KaderCard({required this.kader, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.redPale,
            backgroundImage:
                kader.photoUrl != null && kader.photoUrl!.isNotEmpty
                    ? NetworkImage(kader.photoUrl!)
                    : null,
            child: kader.photoUrl == null || kader.photoUrl!.isEmpty
                ? Text(
                    kader.nama.isNotEmpty ? kader.nama[0].toUpperCase() : 'K',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(kader.nama,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: kader.isActive
                            ? AppColors.successLight
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(kader.isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kader.isActive
                                ? AppColors.success
                                : AppColors.textSecond)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(kader.email,
                    style: const TextStyle(
                        color: AppColors.textSecond, fontSize: 13)),
                const SizedBox(height: 2),
                Text('Terdaftar: ${DateFormatter.toDisplay(kader.createdAt)}',
                    style: const TextStyle(
                        color: AppColors.textSecond, fontSize: 12)),
              ])),
          if (kader.isActive)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecond),
              onSelected: (v) {
                if (v == 'deactivate') onDeactivate();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(children: [
                      Icon(Icons.person_off_rounded,
                          color: AppColors.danger, size: 20),
                      SizedBox(width: 8),
                      Text('Nonaktifkan',
                          style: TextStyle(color: AppColors.danger)),
                    ])),
              ],
            ),
        ]),
      ),
    );
  }
}
