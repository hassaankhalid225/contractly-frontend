import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../models/auth_token_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_exceptions.dart';

@immutable
class NotificationsState {
  final List<AppNotification> items;
  final Set<String> readIds;
  final bool isLoading;
  final NetworkException? error;

  const NotificationsState({
    this.items = const [],
    this.readIds = const {},
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => items.where((n) => !readIds.contains(_id(n))).length;

  static String _id(AppNotification n) =>
      '${n.type}_${n.contractId ?? ''}_${n.paymentId ?? ''}_${n.timestamp.millisecondsSinceEpoch}';

  bool isRead(AppNotification n) => readIds.contains(_id(n));

  NotificationsState copyWith({
    List<AppNotification>? items,
    Set<String>? readIds,
    bool? isLoading,
    NetworkException? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      readIds: readIds ?? this.readIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState()) {
    _loadCachedReadIds();
  }

  static const _readIdsKey = 'notifications_read_ids';

  void _loadCachedReadIds() {
    final box = Hive.box<dynamic>(AppConstants.hiveNotificationsBox);
    final raw = box.get(_readIdsKey);
    if (raw is List) {
      state = state.copyWith(
        readIds: raw.whereType<String>().toSet(),
      );
    }
  }

  Future<void> _persistReadIds() async {
    final box = Hive.box<dynamic>(AppConstants.hiveNotificationsBox);
    await box.put(_readIdsKey, state.readIds.toList());
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.getJson<List<AppNotification>>(
        ApiEndpoints.notifications,
        fromData: (d) => (d as List)
            .whereType<Map>()
            .map((m) =>
                AppNotification.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
      state = state.copyWith(
        items: res.data ?? const <AppNotification>[],
        isLoading: false,
      );
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> markRead(AppNotification n) async {
    final id = NotificationsState._id(n);
    state = state.copyWith(readIds: {...state.readIds, id});
    await _persistReadIds();
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      readIds: state.items.map(NotificationsState._id).toSet(),
    );
    await _persistReadIds();
  }

  void dismiss(AppNotification n) {
    state = state.copyWith(
      items: state.items.where((x) => x != n).toList(growable: false),
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
