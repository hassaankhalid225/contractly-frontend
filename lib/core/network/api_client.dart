import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'api_interceptor.dart';
import 'api_response.dart';
import 'network_exceptions.dart';

/// Singleton wrapper around Dio.
///
/// Every request runs through [ApiInterceptor] which handles auth headers,
/// silent token refresh and error normalisation. Helper methods like
/// [getJson] / [postJson] return parsed [ApiResponse] objects.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.connectTimeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 600,
      ),
    );

    _dio.interceptors.add(ApiInterceptor(_dio));

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint('[Dio] $obj'),
        ),
      );
    }
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  Dio get dio => _dio;

  Future<ApiResponse<T>> getJson<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(dynamic) fromData,
    CancelToken? cancelToken,
  }) =>
      _wrap<T>(
        () => _dio.get<dynamic>(path, queryParameters: query, cancelToken: cancelToken),
        fromData,
      );

  Future<ApiResponse<T>> postJson<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    required T Function(dynamic) fromData,
    Options? options,
  }) =>
      _wrap<T>(
        () => _dio.post<dynamic>(
          path,
          data: body,
          queryParameters: query,
          options: options,
        ),
        fromData,
      );

  Future<ApiResponse<T>> patchJson<T>(
    String path, {
    Object? body,
    required T Function(dynamic) fromData,
  }) =>
      _wrap<T>(
        () => _dio.patch<dynamic>(path, data: body),
        fromData,
      );

  Future<ApiResponse<T>> deleteJson<T>(
    String path, {
    Object? body,
    required T Function(dynamic) fromData,
  }) =>
      _wrap<T>(
        () => _dio.delete<dynamic>(path, data: body),
        fromData,
      );

  Future<ApiResponse<T>> _wrap<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic) fromData,
  ) async {
    try {
      final res = await request();
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final parsed = ApiResponse<T>.fromJson(data, fromData);
        if (!parsed.isSuccess) {
          throw NetworkException(
            type: _statusToType(res.statusCode ?? 0),
            message: parsed.error?.message ?? 'Request failed.',
            code: parsed.error?.code,
            details: parsed.error?.details,
            statusCode: res.statusCode,
          );
        }
        return parsed;
      }
      throw NetworkException(
        type: NetworkExceptionType.unknown,
        message: 'Unexpected response format.',
        statusCode: res.statusCode,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioException(e);
    }
  }

  static NetworkExceptionType _statusToType(int code) {
    if (code == 400) return NetworkExceptionType.badRequest;
    if (code == 401) return NetworkExceptionType.unauthorized;
    if (code == 403) return NetworkExceptionType.forbidden;
    if (code == 404) return NetworkExceptionType.notFound;
    if (code == 422) return NetworkExceptionType.validation;
    if (code >= 500) return NetworkExceptionType.serverError;
    return NetworkExceptionType.unknown;
  }
}
