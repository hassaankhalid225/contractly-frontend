import 'package:intl/intl.dart';

class CurrencyHelper {
  const CurrencyHelper._();

  static String symbolFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'PKR':
        return 'Rs';
      case 'AED':
        return 'AED';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'INR':
        return '₹';
      case 'CAD':
        return r'C$';
      case 'AUD':
        return r'A$';
      default:
        return code.toUpperCase();
    }
  }

  static String format(double amount, String code, {int decimals = 2}) {
    final symbol = symbolFor(code);
    final formatter = NumberFormat.decimalPatternDigits(
      decimalDigits: decimals,
    );
    final value = formatter.format(amount);
    if (symbol.length == 1 || symbol == r'$' || symbol == r'C$' || symbol == r'A$') {
      return '$symbol$value';
    }
    return '$symbol $value';
  }

  static String compact(double amount, String code) {
    final symbol = symbolFor(code);
    final formatter = NumberFormat.compact();
    final value = formatter.format(amount);
    if (symbol.length == 1 || symbol == r'$' || symbol == r'C$' || symbol == r'A$') {
      return '$symbol$value';
    }
    return '$symbol $value';
  }
}
