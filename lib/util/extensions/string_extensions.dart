extension StringExtensions on String {
  String get capitalized {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }

  String get titleCase => split(RegExp(r'[_\s-]+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');

  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => !isBlank;
}

extension NullableStringExtensions on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
  String orDefault(String fallback) =>
      this == null || this!.trim().isEmpty ? fallback : this!;
}
