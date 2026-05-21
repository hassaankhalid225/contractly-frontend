import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/network_exceptions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

@immutable
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final NetworkException? error;
  final String? lastSentOtpPhone;
  final bool isInitializing;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.lastSentOtpPhone,
    this.isInitializing = true,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool clearUser = false,
    bool? isLoading,
    NetworkException? error,
    bool clearError = false,
    String? lastSentOtpPhone,
    bool clearOtpPhone = false,
    bool? isInitializing,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastSentOtpPhone:
          clearOtpPhone ? null : (lastSentOtpPhone ?? this.lastSentOtpPhone),
      isInitializing: isInitializing ?? this.isInitializing,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> initialize() async {
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final cached = StorageService.readCachedUser();
      final hasTokens = await StorageService.hasTokens();
      if (hasTokens && cached != null) {
        state = state.copyWith(
          user: UserModel.fromJson(cached),
          isInitializing: false,
        );
        unawaited(refreshCurrentUser());
        return;
      }
      if (hasTokens) {
        await refreshCurrentUser();
      }
    } catch (_) {
      // ignore errors during silent init
    } finally {
      if (state.isInitializing) {
        state = state.copyWith(isInitializing: false);
      }
    }
  }

  Future<void> refreshCurrentUser() async {
    try {
      final res = await ApiClient.instance.getJson<UserModel>(
        ApiEndpoints.me,
        fromData: (d) => UserModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final user = res.data;
      if (user != null) {
        await StorageService.writeCachedUser(user.toJson());
        state = state.copyWith(user: user, clearError: true);
      }
    } on NetworkException {
      // Silent — caller handles. If 401 the interceptor already cleared tokens.
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final idToken = await AuthService.signInWithGoogle();
      if (idToken == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final res = await ApiClient.instance.postJson<AuthTokenModel>(
        ApiEndpoints.googleLogin,
        body: {'id_token': idToken},
        fromData: (d) =>
            AuthTokenModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final auth = res.data!;
      await StorageService.saveTokens(auth.accessToken, auth.refreshToken);
      await StorageService.writeCachedUser(auth.user.toJson());
      state = state.copyWith(user: auth.user, isLoading: false);
      return true;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: NetworkException(
          type: NetworkExceptionType.unknown,
          message: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiClient.instance.postJson<Map<String, dynamic>>(
        ApiEndpoints.sendOtp,
        body: {'phone': phone},
        fromData: (d) => Map<String, dynamic>.from(d as Map),
      );
      state = state.copyWith(
        isLoading: false,
        lastSentOtpPhone: phone,
      );
      return true;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.postJson<AuthTokenModel>(
        ApiEndpoints.verifyOtp,
        body: {'phone': phone, 'otp': otp},
        fromData: (d) =>
            AuthTokenModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final auth = res.data!;
      await StorageService.saveTokens(auth.accessToken, auth.refreshToken);
      await StorageService.writeCachedUser(auth.user.toJson());
      state = state.copyWith(
        user: auth.user,
        isLoading: false,
        clearOtpPhone: true,
      );
      return true;
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      return false;
    }
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (body.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiClient.instance.patchJson<UserModel>(
        ApiEndpoints.me,
        body: body,
        fromData: (d) => UserModel.fromJson(Map<String, dynamic>.from(d as Map)),
      );
      final updated = res.data!;
      await StorageService.writeCachedUser(updated.toJson());
      state = state.copyWith(user: updated, isLoading: false);
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ApiClient.instance.deleteJson<Map<String, dynamic>>(
        ApiEndpoints.me,
        fromData: (d) =>
            d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
      );
    } on NetworkException catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    } finally {
      await _clearLocalAuth();
      state = state.copyWith(
        clearUser: true,
        isLoading: false,
        clearOtpPhone: true,
      );
    }
  }

  Future<void> signOut() async {
    final refresh = await StorageService.getRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await ApiClient.instance.postJson<Map<String, dynamic>>(
          ApiEndpoints.logout,
          body: {'refresh_token': refresh},
          fromData: (d) =>
              d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{},
        );
      } on NetworkException {
        // ignore — local clear still happens
      }
    }
    await _clearLocalAuth();
    state = const AuthState(isInitializing: false);
  }

  Future<void> _clearLocalAuth() async {
    await StorageService.clearTokens();
    await StorageService.writeCachedUser(null);
    await StorageService.deletePref(AppConstants.prefCachedUser);
    await AuthService.signOutGoogle();
  }

  void clearError() {
    if (state.error != null) state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
