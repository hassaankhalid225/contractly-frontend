import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_exceptions.dart';
import '../services/notification_service.dart';
import 'contract_provider.dart';

@immutable
class PaymentListState {
  final List<PaymentModel> payments;
  final PaymentSummary summary;
  final bool isLoading;
  final NetworkException? error;
  final String? contractFilter;
  final String? statusFilter;

  const PaymentListState({
    this.payments = const [],
    this.summary = PaymentSummary.empty,
    this.isLoading = false,
    this.error,
    this.contractFilter,
    this.statusFilter,
  });

  PaymentListState copyWith({
    List<PaymentModel>? payments,
    PaymentSummary? summary,
    bool? isLoading,
    NetworkException? error,
    bool clearError = false,
    String? contractFilter,
    bool clearContractFilter = false,
    String? statusFilter,
    bool clearStatusFilter = false,
  }) {
    return PaymentListState(
      payments: payments ?? this.payments,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      contractFilter:
          clearContractFilter ? null : (contractFilter ?? this.contractFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentListState> {
  PaymentNotifier(this._ref) : super(const PaymentListState());

  final Ref _ref;

  Future<void> loadPayments({
    String? contractId,
    String? status,
    bool replaceFilters = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      contractFilter:
          replaceFilters ? contractId : (contractId ?? state.contractFilter),
      clearContractFilter: replaceFilters && contractId == null,
      statusFilter:
          replaceFilters ? status : (status ?? state.statusFilter),
      clearStatusFilter: replaceFilters && status == null,
    );

    try {
      final query = <String, dynamic>{};
      final cf = state.contractFilter;
      final sf = state.statusFilter;
      if (cf != null) query['contract_id'] = cf;
      if (sf != null) query['status'] = sf;

      final res = await ApiClient.instance.getJson<List<PaymentModel>>(
        ApiEndpoints.payments,
        query: query,
        fromData: (d) => (d as List)
            .whereType<Map>()
            .map((m) => PaymentModel.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
      final payments = res.data ?? const <PaymentModel>[];
      state = state.copyWith(payments: payments, isLoading: false);
      _scheduleRemindersFor(payments);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadSummary() async {
    try {
      final res = await ApiClient.instance.getJson<PaymentSummary>(
        ApiEndpoints.paymentSummary,
        fromData: (d) =>
            PaymentSummary.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      if (res.data != null) state = state.copyWith(summary: res.data);
    } on NetworkException {
      // non-fatal
    }
  }

  Future<PaymentModel?> create({
    required String contractId,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? notes,
    String status = PaymentStatus.pending,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.postJson<PaymentModel>(
        ApiEndpoints.payments,
        body: {
          'contract_id': contractId,
          'amount': amount,
          'currency': currency,
          'due_date': dueDate.toUtc().toIso8601String(),
          'notes': notes,
          'status': status,
        },
        fromData: (d) =>
            PaymentModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final created = res.data;
      if (created != null) {
        state = state.copyWith(
          payments: [created, ...state.payments],
          isLoading: false,
        );
        _scheduleReminderFor(created);
      } else {
        state = state.copyWith(isLoading: false);
      }
      unawaited(loadSummary());
      return created;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<PaymentModel?> update(String id, Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.patchJson<PaymentModel>(
        ApiEndpoints.payment(id),
        body: body,
        fromData: (d) =>
            PaymentModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final updated = res.data;
      if (updated != null) {
        final list = [...state.payments];
        final i = list.indexWhere((p) => p.id == id);
        if (i >= 0) {
          list[i] = updated;
        } else {
          list.insert(0, updated);
        }
        state = state.copyWith(payments: list, isLoading: false);
        _scheduleReminderFor(updated);
      } else {
        state = state.copyWith(isLoading: false);
      }
      unawaited(loadSummary());
      return updated;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<bool> markPaid(String id) async {
    final updated = await update(id, {
      'status': PaymentStatus.paid,
      'paid_date': DateTime.now().toUtc().toIso8601String(),
    });
    if (updated != null) {
      unawaited(NotificationService.cancel('payment_${updated.id}'));
      return true;
    }
    return false;
  }

  Future<bool> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiClient.instance.deleteJson<Map<String, dynamic>>(
        ApiEndpoints.payment(id),
        fromData: (d) =>
            d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      );
      state = state.copyWith(
        payments: state.payments.where((p) => p.id != id).toList(),
        isLoading: false,
      );
      unawaited(NotificationService.cancel('payment_$id'));
      unawaited(loadSummary());
      return true;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  void _scheduleReminderFor(PaymentModel payment) {
    final contract =
        _ref.read(contractProvider).contracts.where((c) => c.id == payment.contractId);
    final title = contract.isNotEmpty ? contract.first.title : 'Contract';
    unawaited(NotificationService.schedulePaymentReminder(payment, title));
  }

  void _scheduleRemindersFor(List<PaymentModel> payments) {
    for (final p in payments) {
      _scheduleReminderFor(p);
    }
  }
}

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentListState>((ref) {
  return PaymentNotifier(ref);
});
