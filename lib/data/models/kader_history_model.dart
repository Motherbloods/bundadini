import 'package:cloud_firestore/cloud_firestore.dart';

class KaderHistoryModel {
  final String id;
  final String kaderId;
  final String kaderNama;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai;
  final String? alasanPindah;

  const KaderHistoryModel({
    required this.id,
    required this.kaderId,
    required this.kaderNama,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.alasanPindah,
  });

  bool get masihAktif => tanggalSelesai == null;

  factory KaderHistoryModel.fromJson(Map<String, dynamic> json) {
    return KaderHistoryModel(
      id: json['id'] as String? ?? '',
      kaderId: json['kaderId'] as String? ?? '',
      kaderNama: json['kaderNama'] as String? ?? '',
      tanggalMulai:
          (json['tanggalMulai'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tanggalSelesai: (json['tanggalSelesai'] as Timestamp?)?.toDate(),
      alasanPindah: json['alasanPindah'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kaderId': kaderId,
        'kaderNama': kaderNama,
        'tanggalMulai': Timestamp.fromDate(tanggalMulai),
        'tanggalSelesai':
            tanggalSelesai != null ? Timestamp.fromDate(tanggalSelesai!) : null,
        'alasanPindah': alasanPindah,
      };

  KaderHistoryModel copyWith({
    String? id,
    String? kaderId,
    String? kaderNama,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? alasanPindah,
  }) {
    return KaderHistoryModel(
      id: id ?? this.id,
      kaderId: kaderId ?? this.kaderId,
      kaderNama: kaderNama ?? this.kaderNama,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      alasanPindah: alasanPindah ?? this.alasanPindah,
    );
  }
}
