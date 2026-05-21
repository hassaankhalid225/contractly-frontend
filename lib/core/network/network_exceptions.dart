import 'package:dio/dio.dart';

import 'api_response.dart';

enum NetworkExceptionType {
  unauthorized,
  forbidden,
  notFound,
  serverError,
  noInternet,
  timeout,
  badRequest,
  validation,
  cancelled,
  unknown,
}

/// Domain-level exception used everywhere a Dio error needs to leave the
/// network layer.
class NetworkException implements Exception {
  final NetworkExceptionType type;
  final String message;
  final String? code;
  final dynamic details;
  final int? statusCode;

  const NetworkException({
    required this.type,
    required this.message,
    this.code,
    this.details,
    this.statusCode,
  });

  /// User-friendly message that is always safe to display to end users.
  String get friendlyMessage {
    switch (type) {
      case NetworkExceptionType.noInternet:
        return 'No internet connection. Please check your network and try again.';
      case NetworkExceptionType.timeout:
        return 'Request timed out. Please try again.';
      case NetworkExceptionType.unauthorized:
        return 'Your session has expired. Please sign in again.';
      case NetworkExceptionType.forbidden:
        return "You don't have permission to perform this action.";
      case NetworkExceptionType.notFound:
        return 'We couldn\'t find what you were looking for.';
      case NetworkExceptionType.serverError:
        return 'Something went wrong on our end. Please try again shortly.';
      case NetworkExceptionType.badRequest:
      case NetworkExceptionType.validation:
        return message;
      case NetworkExceptionType.cancelled:
        return 'Request cancelled.';
      case NetworkExceptionType.unknown:
        return message.isNotEmpty
            ? message
            : 'Something went wrong. Please try again.';
    }
  }

  factory NetworkException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          type: NetworkExceptionType.timeout,
          message: 'Request timed out.',
        );
      case DioExceptionType.connectionError:
        return const NetworkException(
          type: NetworkExceptionType.noInternet,
          message: 'No internet connection.',
        );
      case DioExceptionType.cancel:
        return const NetworkException(
          type: NetworkExceptionType.cancelled,
          message: 'Request cancelled.',
        );
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          return NetworkException.fromResponse(response);
        }
        return NetworkException(
          type: NetworkExceptionType.unknown,
          message: e.message ?? 'Unknown error',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return NetworkException(
          type: NetworkExceptionType.unknown,
          message: e.message ?? 'Unknown error',
        );
    }
  }

  factory NetworkException.fromResponse(Response response) {
    final status = response.statusCode ?? 0;
    final data = response.data;
    String message = 'Request failed.';
    String? code;
    dynamic details;

    if (data is Map<String, dynamic>) {
      final errorBlock = data['error'];
      if (errorBlock is Map<String, dynamic>) {
        final apiError = ApiError.fromJson(errorBlock);
        message = apiError.message;
        code = apiError.code;
        details = apiError.details;
      } else if (data['message'] is String) {
        message = data['message'] as String;
      }
    }

    NetworkExceptionType type;
    if (status == 400) {
      type = NetworkExceptionType.badRequest;
    } else if (status == 401) {
      type = NetworkExceptionType.unauthorized;
    } else if (status == 403) {
      type = NetworkExceptionType.forbidden;
    } else if (status == 404) {
      type = NetworkExceptionType.notFound;
    } else if (status == 422) {
      type = NetworkExceptionType.validation;
    } else if (status >= 500) {
      type = NetworkExceptionType.serverError;
    } else {
      type = NetworkExceptionType.unknown;
    }

    return NetworkException(
      type: type,
      message: message,
      code: code,
      details: details,
      statusCode: status,
    );
  }

  @override
  String toString() =>
      'NetworkException(type=$type, code=$code, status=$statusCode, message=$message)';
}
