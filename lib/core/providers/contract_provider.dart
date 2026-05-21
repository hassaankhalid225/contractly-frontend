import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_exceptions.dart';
import '../services/notification_service.dart';

@immutable
class ContractListState {
  final List<ContractModel> contracts;
  final ContractStatsSummary stats;
  final bool isLoading;
  final NetworkException? error;
  final String? statusFilter;
  final String? searchQuery;

  const ContractListState({
    this.contracts = const [],
    this.stats = ContractStatsSummary.empty,
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.searchQuery,
  });

  ContractListState copyWith({
    List<ContractModel>? contracts,
    ContractStatsSummary? stats,
    bool? isLoading,
    NetworkException? error,
    bool clearError = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return ContractListState(
      contracts: contracts ?? this.contracts,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

class ContractNotifier extends StateNotifier<ContractListState> {
  ContractNotifier() : super(const ContractListState());

  Future<void> loadContracts({
    String? status,
    String? search,
    bool replaceFilters = false,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      statusFilter: replaceFilters ? status : (status ?? state.statusFilter),
      clearStatusFilter: replaceFilters && status == null,
      searchQuery: replaceFilters ? search : (search ?? state.searchQuery),
      clearSearch: replaceFilters && search == null,
    );

    try {
      final query = <String, dynamic>{};
      final effectiveStatus = state.statusFilter;
      final effectiveSearch = state.searchQuery;
      if (effectiveStatus != null) query['status'] = effectiveStatus;
      if (effectiveSearch != null && effectiveSearch.isNotEmpty) {
        query['search'] = effectiveSearch;
      }

      final res = await ApiClient.instance.getJson<List<ContractModel>>(
        ApiEndpoints.contracts,
        query: query,
        fromData: (d) => (d as List)
            .whereType<Map>()
            .map((m) => ContractModel.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

      final contracts = res.data ?? const <ContractModel>[];
      state = state.copyWith(contracts: contracts, isLoading: false);
      _scheduleRemindersFor(contracts);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> loadStats() async {
    try {
      final res = await ApiClient.instance.getJson<ContractStatsSummary>(
        ApiEndpoints.contractStats,
        fromData: (d) => ContractStatsSummary.fromJson(
          Map<String, dynamic>.from(d as Map),
        ),
      );
      if (res.data != null) {
        state = state.copyWith(stats: res.data);
      }
    } on NetworkException {
      // non-fatal
    }
  }

  Future<ContractModel?> createContract(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.postJson<ContractModel>(
        ApiEndpoints.contracts,
        body: body,
        fromData: (d) =>
            ContractModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final created = res.data;
      if (created != null) {
        state = state.copyWith(
          contracts: [created, ...state.contracts],
          isLoading: false,
        );
        unawaited(NotificationService.scheduleContractReminders(created));
        unawaited(loadStats());
      } else {
        state = state.copyWith(isLoading: false);
      }
      return created;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<ContractModel?> updateContract(
    String id,
    Map<String, dynamic> body,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.patchJson<ContractModel>(
        ApiEndpoints.contract(id),
        body: body,
        fromData: (d) =>
            ContractModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final updated = res.data;
      if (updated != null) {
        _replace(updated);
        unawaited(NotificationService.scheduleContractReminders(updated));
        unawaited(loadStats());
      }
      state = state.copyWith(isLoading: false);
      return updated;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<bool> deleteContract(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiClient.instance.deleteJson<Map<String, dynamic>>(
        ApiEndpoints.contract(id),
        fromData: (d) =>
            d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      );
      state = state.copyWith(
        contracts: state.contracts.where((c) => c.id != id).toList(),
        isLoading: false,
      );
      unawaited(NotificationService.cancel('contract_${id}_14d'));
      unawaited(NotificationService.cancel('contract_${id}_7d'));
      unawaited(NotificationService.cancel('contract_${id}_1d'));
      unawaited(loadStats());
      return true;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<ContractModel?> uploadPdf(String contractId, File pdf) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdf.path,
          filename: pdf.uri.pathSegments.last,
        ),
      });
      final res = await ApiClient.instance.postJson<ContractModel>(
        ApiEndpoints.uploadContractPdf(contractId),
        body: form,
        options: Options(contentType: 'multipart/form-data'),
        fromData: (d) =>
            ContractModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final updated = res.data;
      if (updated != null) _replace(updated);
      state = state.copyWith(isLoading: false);
      return updated;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<ContractModel?> signContract(
    String contractId,
    Uint8List signaturePngBytes,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final b64 = base64Encode(signaturePngBytes);
      final res = await ApiClient.instance.postJson<ContractModel>(
        ApiEndpoints.signContract(contractId),
        body: {'signature_image_base64': b64},
        fromData: (d) =>
            ContractModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final updated = res.data;
      if (updated != null) _replace(updated);
      state = state.copyWith(isLoading: false);
      unawaited(loadStats());
      return updated;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  /// AI generation does not mutate state; returns the markdown string.
  Future<String?> generateAiContract(Map<String, dynamic> body) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.postJson<String>(
        ApiEndpoints.aiGenerate,
        body: body,
        fromData: (d) {
          final map = Map<String, dynamic>.from(d as Map);
          return (map['contract_text_markdown'] as String?) ?? '';
        },
      );
      state = state.copyWith(isLoading: false);
      return res.data;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  Future<ContractAnalysis?> analyzeContract({
    String? contractText,
    String? pdfUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.postJson<ContractAnalysis>(
        ApiEndpoints.aiAnalyze,
        body: {
          if (contractText != null) 'contract_text': contractText,
          if (pdfUrl != null) 'pdf_url': pdfUrl,
        },
        fromData: (d) =>
            ContractAnalysis.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      state = state.copyWith(isLoading: false);
      return res.data;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return null;
    }
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }

  ContractModel? findById(String id) {
    for (final c in state.contracts) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<ContractModel?> fetchById(String id) async {
    try {
      final res = await ApiClient.instance.getJson<ContractModel>(
        ApiEndpoints.contract(id),
        fromData: (d) =>
            ContractModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final c = res.data;
      if (c != null) _replace(c);
      return c;
    } on NetworkException catch (e) {
      state = state.copyWith(error: e);
      return null;
    }
  }

  void _replace(ContractModel updated) {
    final index = state.contracts.indexWhere((c) => c.id == updated.id);
    if (index == -1) {
      state = state.copyWith(contracts: [updated, ...state.contracts]);
    } else {
      final list = [...state.contracts];
      list[index] = updated;
      state = state.copyWith(contracts: list);
    }
  }

  void _scheduleRemindersFor(List<ContractModel> contracts) {
    for (final c in contracts) {
      unawaited(NotificationService.scheduleContractReminders(c));
    }
  }
}

final contractProvider =
    StateNotifierProvider<ContractNotifier, ContractListState>((ref) {
  return ContractNotifier();
});
