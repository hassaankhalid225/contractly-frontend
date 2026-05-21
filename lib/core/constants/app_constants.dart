/// Static, environment-derived configuration.
class AppConstants {
  const AppConstants._();

  /// Override at build time:
  ///   flutter run --dart-define=API_BASE_URL=https://api.contractly.app
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Optional Google client id (web only — mobile uses GoogleService files).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String hivePrefsBox = 'contractly.prefs';
  static const String hiveNotificationsBox = 'contractly.notifications';

  static const String prefOnboardingSeen = 'onboarding_seen';
  static const String prefCurrency = 'currency';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefCachedUser = 'cached_user';

  static const List<String> supportedCurrencies = [
    'USD',
    'PKR',
    'AED',
    'GBP',
    'EUR',
    'INR',
    'CAD',
    'AUD',
  ];

  static const List<String> testPhoneNumbers = [
    '+923001234567',
    '+923009876543',
  ];
  static const String testOtp = '123456';

  static const String privacyPolicyUrl = 'https://contractly.app/privacy';
  static const String termsUrl = 'https://contractly.app/terms';

  static const String appName = 'Contractly';
  static const String tagline = 'Your freelance contracts, always in control.';
}
