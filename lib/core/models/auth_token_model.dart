import 'package:flutter/foundation.dart';

import 'user_model.dart';

@immutable
class AuthTokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final UserModel user;

  const AuthTokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.tokenType = 'bearer',
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) => AuthTokenModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: (json['token_type'] as String?) ?? 'bearer',
        user: UserModel.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
      );
}

@immutable
class AppNotification {
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? contractId;
  final String? paymentId;

  const AppNotification({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.contractId,
    this.paymentId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        type: (json['type'] as String?) ?? 'info',
        title: (json['title'] as String?) ?? '',
        message: (json['message'] as String?) ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
                DateTime.now(),
        contractId: json['contract_id'] as String?,
        paymentId: json['payment_id'] as String?,
      );
}
