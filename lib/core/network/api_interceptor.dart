import 'dart:async';

import 'package:dio/dio.dart';

import '../services/storage_service.dart';
import 'api_endpoints.dart';

/// Centralized auth header attachment, silent refresh and forced sign-out.
///
/// On a 401 from a non-refresh endpoint we attempt to refresh the access
/// token using the stored refresh token and replay the original request once.
/// If the refresh also fails the local tokens are cleared and a top-level
/// listener (registered via [ApiInterceptor.onAuthLost]) is invoked so the
/// router can redirect to /auth.
class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._dio);

  final Dio _dio;

  /// Set by [setOnAuthLost]. Called when refresh fails and the user must
  /// re-authenticate.
  static void Function()? _onAuthLost;
  static void setOnAuthLost(void Function() callback) {
    _onAuthLost = callback;
  }

  /// Used to deduplicate concurrent refresh attempts.
  static Future<String?>? _refreshFuture;

  static const _skipAuthPaths = {
    ApiEndpoints.googleLogin,
    ApiEndpoints.sendOtp,
    ApiEndpoints.verifyOtp,
    ApiEndpoints.refreshToken,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final skip = _skipAuthPaths.any((p) => path.endsWith(p));
    if (!skip) {
      final token = await StorageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final status = response.statusCode ?? 0;
    if (status == 401 && !_isAuthEndpoint(response.requestOptions.path)) {
      final newAccess = await _refreshOnce();
      if (newAccess != null) {
        final retry = await _retry(response.requestOptions, newAccess);
        return handler.resolve(retry);
      } else {
        await StorageService.clearTokens();
        _onAuthLost?.call();
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;
    if (status == 401 && !_isAuthEndpoint(err.requestOptions.path)) {
      final newAccess = await _refreshOnce();
      if (newAccess != null) {
        try {
          final retry = await _retry(err.requestOptions, newAccess);
          return handler.resolve(retry);
        } on DioException catch (e) {
          return handler.next(e);
        }
      } else {
        await StorageService.clearTokens();
        _onAuthLost?.call();
      }
    }
    handler.next(err);
  }

  bool _isAuthEndpoint(String path) =>
      _skipAuthPaths.any((p) => path.endsWith(p));

  Future<String?> _refreshOnce() async {
    _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
    return _refreshFuture;
  }

  Future<String?> _doRefresh() async {
    final refresh = await StorageService.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final res = await Dio(
        BaseOptions(
          baseUrl: _dio.options.baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          headers: const {'Content-Type': 'application/json'},
        ),
      ).post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refresh},
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final body = res.data as Map<String, dynamic>;
        final data = body['data'];
        if (body['success'] == true && data is Map<String, dynamic>) {
          final newToken = data['access_token'] as String?;
          if (newToken != null && newToken.isNotEmpty) {
            await StorageService.saveAccessToken(newToken);
            return newToken;
          }
        }
      }
    } on DioException {
      // fall through to null
    }
    return null;
  }

  Future<Response<dynamic>> _retry(RequestOptions opts, String token) async {
    final newOpts = Options(
      method: opts.method,
      headers: {
        ...opts.headers,
        'Authorization': 'Bearer $token',
      },
      contentType: opts.contentType,
      responseType: opts.responseType,
      validateStatus: opts.validateStatus,
    );
    return _dio.request<dynamic>(
      opts.path,
      data: opts.data,
      queryParameters: opts.queryParameters,
      options: newOpts,
      cancelToken: opts.cancelToken,
    );
  }
}
