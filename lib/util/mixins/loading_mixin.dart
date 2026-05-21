import 'package:flutter/material.dart';

/// Mixin for stateful widgets that need a simple isLoading flag with safe
/// `setState` calls (only fires when mounted).
mixin LoadingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<R> withLoading<R>(Future<R> Function() task) async {
    setLoading(true);
    try {
      return await task();
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    if (!mounted) return;
    if (_isLoading == value) return;
    setState(() => _isLoading = value);
  }
}
