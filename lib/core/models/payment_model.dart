import 'package:flutter/foundation.dart';

class PaymentStatus {
  static const String pending = 'pending';
  static const String paid = 'paid';
  static const String overdue = 'overdue';
  static const String cancelled = 'cancelled';

  static const List<String> all = [pending, paid, overdue, cancelled];

  static String label(String status) {
    switch (status) {
      case paid:
        return 'Paid';
      case overdue:
        return 'Overdue';
      case cancelled:
        return 'Cancelled';
      case pending:
      default:
        return 'Pending';
    }
  }
}

@immutable
class PaymentModel {
  final String id;
  final String contractId;
  final String userId;
  final double amount;
  final String currency;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentModel({
    required this.id,
    required this.contractId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.paidDate,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return PaymentModel(
      id: json['id'] as String,
      contractId: json['contract_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'USD',
      dueDate: parseDate(json['due_date']) ?? DateTime.now(),
      paidDate: parseDate(json['paid_date']),
      status: (json['status'] as String?) ?? PaymentStatus.pending,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contract_id': contractId,
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'due_date': dueDate.toIso8601String(),
        'paid_date': paidDate?.toIso8601String(),
        'status': status,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class PaymentSummary {
  final double totalEarned;
  final double totalPending;
  final double totalOverdue;
  final int overdueCount;
  final int pendingCount;
  final int paidCount;

  const PaymentSummary({
    required this.totalEarned,
    required this.totalPending,
    required this.totalOverdue,
    required this.overdueCount,
    required this.pendingCount,
    required this.paidCount,
  });

  static const empty = PaymentSummary(
    totalEarned: 0,
    totalPending: 0,
    totalOverdue: 0,
    overdueCount: 0,
    pendingCount: 0,
    paidCount: 0,
  );

  factory PaymentSummary.fromJson(Map<String, dynamic> json) => PaymentSummary(
        totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
        totalPending: (json['total_pending'] as num?)?.toDouble() ?? 0,
        totalOverdue: (json['total_overdue'] as num?)?.toDouble() ?? 0,
        overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
        pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
        paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
      );
}
