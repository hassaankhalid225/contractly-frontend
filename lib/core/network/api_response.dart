/// Generic wrapper around the standard `{ success, data, message, error }`
/// envelope returned by the backend.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiError? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final success = (json['success'] as bool?) ?? false;
    final dynamic rawData = json['data'];
    final dynamic rawError = json['error'];

    return ApiResponse<T>(
      success: success,
      data: rawData == null ? null : fromJsonT(rawData),
      message: json['message'] as String?,
      error: rawError is Map<String, dynamic>
          ? ApiError.fromJson(rawError)
          : null,
    );
  }

  factory ApiResponse.successOnly(T? data, {String? message}) =>
      ApiResponse<T>(success: true, data: data, message: message);

  bool get isSuccess => success && error == null;
}

class ApiError {
  final String code;
  final String message;
  final dynamic details;

  const ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: (json['code'] as String?) ?? 'UNKNOWN',
        message: (json['message'] as String?) ?? 'Something went wrong.',
        details: json['details'],
      );

  @override
  String toString() => 'ApiError($code, $message)';
}
