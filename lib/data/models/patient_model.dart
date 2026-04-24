import 'package:cloud_firestore/cloud_firestore.dart';

enum GolonganDarah {
  a,
  b,
  ab,
  o,
}

extension GolonganDarahExt on GolonganDarah {
  String get value => name.toUpperCase();

  static GolonganDarah fromString(String s) {
    return GolonganDarah.values.firstWhere(
      (e) => e.name.toLowerCase() == s.toLowerCase(),
      orElse: () => GolonganDarah.o,
    );
  }
}

enum StatusPasien { aktif, pindah, selesai }

extension StatusPasienExt on StatusPasien {
  String get value => name;
  String get label {
    switch (this) {
      case StatusPasien.aktif:
        return 'Aktif';
      case StatusPasien.pindah:
        return 'Pindah';
      case StatusPasien.selesai:
        return 'Selesai';
    }
  }

  static StatusPasien fromString(String s) => StatusPasien.values
      .firstWhere((e) => e.name == s, orElse: () => StatusPasien.aktif);
}

class PatientModel {
  final String id;
  final String nik;
  final String nama;
  final String tempatLahir;
  final DateTime tanggalLahir;
  final String alamat;
  final String noHp;
  final DateTime hpht;
  final GolonganDarah golonganDarah;
  final String fotoUrl;
  final String kaderId;
  final StatusPasien status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PatientModel({
    required this.id,
    required this.nik,
    required this.nama,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.alamat,
    required this.noHp,
    required this.hpht,
    required this.golonganDarah,
    required this.fotoUrl,
    required this.kaderId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      tempatLahir: json['tempatLahir'] as String? ?? '',
      tanggalLahir:
          (json['tanggalLahir'] as Timestamp?)?.toDate() ?? DateTime.now(),
      alamat: json['alamat'] as String? ?? '',
      noHp: json['noHp'] as String? ?? '',
      hpht: (json['hpht'] as Timestamp?)?.toDate() ?? DateTime.now(),
      golonganDarah:
          GolonganDarahExt.fromString(json['golonganDarah'] as String? ?? 'O'),
      fotoUrl: json['fotoUrl'] as String? ?? '',
      kaderId: json['kaderId'] as String? ?? '',
      status: StatusPasienExt.fromString(json['status'] as String? ?? 'aktif'),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nik': nik,
        'nama': nama,
        'tempatLahir': tempatLahir,
        'tanggalLahir': Timestamp.fromDate(tanggalLahir),
        'alamat': alamat,
        'noHp': noHp,
        'hpht': Timestamp.fromDate(hpht),
        'golonganDarah': golonganDarah.value,
        'fotoUrl': fotoUrl,
        'kaderId': kaderId,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  PatientModel copyWith({
    String? id,
    String? nik,
    String? nama,
    String? tempatLahir,
    DateTime? tanggalLahir,
    String? alamat,
    String? noHp,
    DateTime? hpht,
    GolonganDarah? golonganDarah,
    String? fotoUrl,
    String? kaderId,
    StatusPasien? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      alamat: alamat ?? this.alamat,
      noHp: noHp ?? this.noHp,
      hpht: hpht ?? this.hpht,
      golonganDarah: golonganDarah ?? this.golonganDarah,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      kaderId: kaderId ?? this.kaderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'PatientModel(id: $id, nama: $nama, nik: $nik)';
}
