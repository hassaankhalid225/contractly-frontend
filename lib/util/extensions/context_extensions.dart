import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  MediaQueryData get mq => MediaQuery.of(this);
  Size get screenSize => mq.size;
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;
  EdgeInsets get viewPadding => mq.viewPadding;
  bool get isPhone => mq.size.shortestSide < 600;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  Future<void> hideKeyboard() async {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
