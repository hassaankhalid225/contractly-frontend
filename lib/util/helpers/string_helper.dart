class StringHelper {
  const StringHelper._();

  static String initials(String? source) {
    if (source == null) return '?';
    final s = source.trim();
    if (s.isEmpty) return '?';
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String truncate(String s, int max, {String tail = '…'}) {
    if (s.length <= max) return s;
    return s.substring(0, max).trimRight() + tail;
  }

  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s.substring(0, 1).toUpperCase() + s.substring(1);
  }

  static String titleize(String s) =>
      s.split(RegExp(r'[_\s-]+')).map(capitalize).join(' ');
}
