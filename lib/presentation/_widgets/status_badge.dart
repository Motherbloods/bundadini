import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/examination_model.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isJanin;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.isJanin = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config();
    final fs = large ? 15.0 : 13.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: TextStyle(fontSize: fs)),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w600,
              color: config.fg,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _config() {
    if (isJanin) {
      switch (status) {
        case JaninStatus.djjRendah:
          return const _BadgeConfig('🔴', AppStrings.statusDjjRendah,
              AppColors.dangerLight, AppColors.danger);
        case JaninStatus.djjTinggi:
          return const _BadgeConfig('🔴', AppStrings.statusDjjTinggi,
              AppColors.dangerLight, AppColors.danger);
        default: // normal
          return const _BadgeConfig('✅', AppStrings.statusNormal,
              AppColors.successLight, AppColors.success);
      }
    }
    switch (status) {
      case ExaminationStatus.perluPerhatian:
        return const _BadgeConfig('⚠️', AppStrings.statusPerluPerhatian,
            AppColors.warningLight, AppColors.warning);
      case ExaminationStatus.risikoTinggi:
        return const _BadgeConfig('🔴', AppStrings.statusRisikoTinggi,
            AppColors.dangerLight, AppColors.danger);
      default: // normal
        return const _BadgeConfig('✅', AppStrings.statusNormal,
            AppColors.successLight, AppColors.success);
    }
  }
}

class _BadgeConfig {
  final String emoji;
  final String label;
  final Color bg;
  final Color fg;
  const _BadgeConfig(this.emoji, this.label, this.bg, this.fg);
}

/// Badge LILA — Normal / KEK
class LilaBadge extends StatelessWidget {
  final double lila;
  const LilaBadge({super.key, required this.lila});

  @override
  Widget build(BuildContext context) {
    final isKek = lila < 23.5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isKek ? AppColors.warningLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isKek ? '⚠️ KEK' : '✅ Normal',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isKek ? AppColors.warning : AppColors.success,
        ),
      ),
    );
  }
}
