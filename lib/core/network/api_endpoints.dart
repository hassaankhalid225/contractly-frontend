/// All API paths in one place. Paths are joined with the base URL by
/// [ApiClient] so they should not be absolute.
class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String googleLogin = '/auth/google';
  static const String sendOtp = '/auth/phone/send-otp';
  static const String verifyOtp = '/auth/phone/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // Users
  static const String me = '/users/me';

  // Contracts
  static const String contracts = '/contracts';
  static const String contractStats = '/contracts/stats/summary';
  static String contract(String id) => '/contracts/$id';
  static String uploadContractPdf(String id) => '/contracts/$id/upload-pdf';
  static String signContract(String id) => '/contracts/$id/sign';

  // Payments
  static const String payments = '/payments';
  static const String paymentSummary = '/payments/summary';
  static String payment(String id) => '/payments/$id';

  // AI
  static const String aiGenerate = '/ai/generate-contract';
  static const String aiAnalyze = '/ai/analyze-contract';
  static const String aiTemplate = '/ai/suggest-template';

  // Notifications
  static const String notifications = '/notifications';
}
