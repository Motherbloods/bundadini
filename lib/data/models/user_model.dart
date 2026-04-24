import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { bidan, kader }

extension UserRoleExt on UserRole {
  String get value => name; // 'bidan' | 'kader'
  static UserRole fromString(String s) => UserRole.values
      .firstWhere((e) => e.name == s, orElse: () => UserRole.kader);
}

class UserModel {
  final String id;
  final String email;
  final String nama;
  final UserRole role;
  final String createdBy;
  final DateTime createdAt;
  final String? photoUrl;
  final String? namaPuskesmas; // hanya bidan, untuk header PDF
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.nama,
    required this.role,
    required this.createdBy,
    required this.createdAt,
    this.photoUrl,
    this.namaPuskesmas,
    required this.isActive,
  });

  bool get isBidan => role == UserRole.bidan;
  bool get isKader => role == UserRole.kader;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      role: UserRoleExt.fromString(json['role'] as String? ?? 'kader'),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: json['photoUrl'] as String?,
      namaPuskesmas: json['namaPuskesmas'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nama': nama,
        'role': role.value,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'photoUrl': photoUrl,
        'namaPuskesmas': namaPuskesmas,
        'isActive': isActive,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? nama,
    UserRole? role,
    String? createdBy,
    DateTime? createdAt,
    String? photoUrl,
    String? namaPuskesmas,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nama: nama ?? this.nama,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      namaPuskesmas: namaPuskesmas ?? this.namaPuskesmas,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'UserModel(id: $id, nama: $nama, role: ${role.value})';
}
