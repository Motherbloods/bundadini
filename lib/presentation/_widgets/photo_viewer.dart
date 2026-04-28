import 'package:flutter/material.dart';

class PhotoViewer {
  /// Tampilkan foto fullscreen sebagai dialog
  static void show(
    BuildContext context, {
    required String imageUrl,
    String? heroTag,
    String? nama,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _PhotoViewerDialog(
        imageUrl: imageUrl,
        heroTag: heroTag,
        nama: nama,
      ),
    );
  }
}

class _PhotoViewerDialog extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;
  final String? nama;

  const _PhotoViewerDialog({
    required this.imageUrl,
    this.heroTag,
    this.nama,
  });

  @override
  State<_PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<_PhotoViewerDialog> {
  final _transformCtrl = TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(children: [
        // Background tap untuk tutup (hanya jika tidak zoom)
        GestureDetector(
          onTap: _isZoomed ? _resetZoom : () => Navigator.pop(context),
          child: Container(color: Colors.transparent),
        ),

        // Foto fullscreen dengan pinch-to-zoom
        Center(
          child: InteractiveViewer(
            transformationController: _transformCtrl,
            minScale: 0.8,
            maxScale: 4.0,
            onInteractionEnd: (details) {
              final scale = _transformCtrl.value.getMaxScaleOnAxis();
              setState(() => _isZoomed = scale > 1.05);
            },
            child: widget.heroTag != null
                ? Hero(
                    tag: widget.heroTag!,
                    child: _buildImage(),
                  )
                : _buildImage(),
          ),
        ),

        // Tombol tutup di pojok kanan atas
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),

        // Nama pasien di bawah jika ada
        if (widget.nama != null)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.black54,
              child: Text(
                widget.nama!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
          SizedBox(height: 12),
          Text('Gagal memuat foto',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ]),
      ),
    );
  }
}
