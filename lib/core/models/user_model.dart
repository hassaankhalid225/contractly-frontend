import 'package:flutter/foundation.dart';

@immutable
class UserModel {
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String provider;
  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.provider,
    required this.createdAt,
    required this.isActive,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      provider: (json['provider'] as String?) ?? 'phone',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'photo_url': photoUrl,
        'provider': provider,
        'created_at': createdAt.toIso8601String(),
        'is_active': isActive,
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      provider: provider,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (email != null && email!.contains('@')) return email!.split('@').first;
    return phone ?? 'Friend';
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
