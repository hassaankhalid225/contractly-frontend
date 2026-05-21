import 'package:flutter/foundation.dart';

class ContractStatus {
  static const String draft = 'draft';
  static const String active = 'active';
  static const String expiringSoon = 'expiring_soon';
  static const String expired = 'expired';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [
    draft,
    active,
    expiringSoon,
    expired,
    completed,
    cancelled,
  ];

  static String label(String status) {
    switch (status) {
      case active:
        return 'Active';
      case expiringSoon:
        return 'Expiring Soon';
      case expired:
        return 'Expired';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case draft:
      default:
        return 'Draft';
    }
  }
}

class WorkType {
  static const String webDev = 'web_dev';
  static const String design = 'design';
  static const String content = 'content';
  static const String video = 'video';
  static const String other = 'other';

  static const Map<String, String> labels = {
    webDev: 'Web Development',
    design: 'Design',
    content: 'Content Writing',
    video: 'Video Editing',
    other: 'Other',
  };

  static String label(String? value) =>
      labels[value ?? other] ?? labels[other]!;
}

@immutable
class ContractModel {
  final String id;
  final String userId;
  final String title;
  final String clientName;
  final String? clientEmail;
  final String? description;
  final double value;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final String? workType;
  final String? pdfUrl;
  final String? signatureUrl;
  final DateTime? signedAt;
  final Map<String, dynamic>? aiAnalysis;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.clientName,
    required this.value,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.clientEmail,
    this.description,
    this.startDate,
    this.endDate,
    this.workType,
    this.pdfUrl,
    this.signatureUrl,
    this.signedAt,
    this.aiAnalysis,
    this.notes,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return ContractModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] as String?) ?? '',
      clientName: (json['client_name'] as String?) ?? '',
      clientEmail: json['client_email'] as String?,
      description: json['description'] as String?,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] as String?) ?? 'USD',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: (json['status'] as String?) ?? ContractStatus.draft,
      workType: json['work_type'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      signedAt: parseDate(json['signed_at']),
      aiAnalysis: json['ai_analysis'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['ai_analysis'] as Map)
          : null,
      notes: json['notes'] as String?,
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'client_name': clientName,
        'client_email': clientEmail,
        'description': description,
        'value': value,
        'currency': currency,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'work_type': workType,
        'pdf_url': pdfUrl,
        'signature_url': signatureUrl,
        'signed_at': signedAt?.toIso8601String(),
        'ai_analysis': aiAnalysis,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  bool get isSigned => signatureUrl != null && signatureUrl!.isNotEmpty;

  /// 0..1 of contract duration elapsed (clamped). Null when dates missing.
  double? get progress {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return null;
    final total = e.difference(s).inSeconds;
    if (total <= 0) return 1;
    final elapsed = DateTime.now().difference(s).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Days remaining until end_date (negative if past).
  int? get daysRemaining {
    final e = endDate;
    if (e == null) return null;
    final diff = e.difference(DateTime.now());
    return diff.inDays;
  }
}

class ContractStatsSummary {
  final int total;
  final int active;
  final int expiring;
  final int expired;
  final int draft;
  final int completed;
  final double totalValue;
  final Map<String, double> currencyBreakdown;

  const ContractStatsSummary({
    required this.total,
    required this.active,
    required this.expiring,
    required this.expired,
    required this.draft,
    required this.completed,
    required this.totalValue,
    required this.currencyBreakdown,
  });

  static const empty = ContractStatsSummary(
    total: 0,
    active: 0,
    expiring: 0,
    expired: 0,
    draft: 0,
    completed: 0,
    totalValue: 0,
    currencyBreakdown: {},
  );

  factory ContractStatsSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['currency_breakdown'];
    final map = <String, double>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String && v is num) map[k] = v.toDouble();
      });
    }
    return ContractStatsSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      expiring: (json['expiring'] as num?)?.toInt() ?? 0,
      expired: (json['expired'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      currencyBreakdown: map,
    );
  }
}

class ContractAnalysis {
  final String riskLevel;
  final String summary;
  final List<RiskyClause> riskyClauses;
  final List<String> missingSections;
  final List<String> recommendations;
  final int freelancerProtectionScore;

  const ContractAnalysis({
    required this.riskLevel,
    required this.summary,
    required this.riskyClauses,
    required this.missingSections,
    required this.recommendations,
    required this.freelancerProtectionScore,
  });

  factory ContractAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractAnalysis(
      riskLevel: (json['risk_level'] as String?)?.toLowerCase() ?? 'low',
      summary: (json['summary'] as String?) ?? '',
      riskyClauses: ((json['risky_clauses'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => RiskyClause.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      missingSections: ((json['missing_sections'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      recommendations: ((json['recommendations'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      freelancerProtectionScore:
          (json['freelancer_protection_score'] as num?)?.toInt() ?? 5,
    );
  }
}

class RiskyClause {
  final String clause;
  final String risk;
  final String severity;

  const RiskyClause({
    required this.clause,
    required this.risk,
    required this.severity,
  });

  factory RiskyClause.fromJson(Map<String, dynamic> json) => RiskyClause(
        clause: (json['clause'] as String?) ?? '',
        risk: (json['risk'] as String?) ?? '',
        severity: ((json['severity'] as String?) ?? 'low').toLowerCase(),
      );
}
