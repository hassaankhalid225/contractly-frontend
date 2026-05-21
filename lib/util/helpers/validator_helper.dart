class ValidatorHelper {
  const ValidatorHelper._();

  static final RegExp _emailRegExp = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(r'^\+?\d{8,15}$');

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return required ? 'Email is required.' : null;
    if (!_emailRegExp.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim().replaceAll(RegExp(r'\s|-'), '') ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    if (!_phoneRegExp.hasMatch(v)) {
      return 'Use international format (e.g. +14155551234).';
    }
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    final v = value?.trim() ?? '';
    if (v.length != length || int.tryParse(v) == null) {
      return 'Enter the $length-digit code we sent you.';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required.';
    final n = double.tryParse(v);
    if (n == null) return '$label must be a number.';
    if (n < 0) return '$label must be 0 or greater.';
    return null;
  }
}
