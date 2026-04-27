import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class NetworkImageFallback extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final IconData fallbackIcon;

  const NetworkImageFallback({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fallbackIcon = Icons.person_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final Widget defaultFallback = Container(
      width: width,
      height: height,
      color: AppColors.redPale,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(fallbackIcon, color: AppColors.primary, size: width * 0.5),
        ],
      ),
    );

    final Widget offlineFallback = Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppColors.textHint, size: width * 0.35),
          const SizedBox(height: 4),
          if (width > 60)
            const Text(
              'Tidak ada\nkoneksi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );

    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: placeholder ?? defaultFallback,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        url!,
        width: width,
        height: height,
        fit: fit,
        // Tampilkan loading shimmer saat gambar sedang dimuat
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.divider,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        },
        // Tampilkan fallback offline saat gagal load
        errorBuilder: (_, error, __) => offlineFallback,
      ),
    );
  }
}
