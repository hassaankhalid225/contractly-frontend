import 'package:intl/intl.dart';

class DateHelper {
  const DateHelper._();

  static final DateFormat _full = DateFormat('MMM d, yyyy');
  static final DateFormat _short = DateFormat('MMM d');
  static final DateFormat _withTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _iso = DateFormat('yyyy-MM-dd');

  static String formatFull(DateTime d) => _full.format(d);
  static String formatShort(DateTime d) => _short.format(d);
  static String formatWithTime(DateTime d) => _withTime.format(d);
  static String formatIso(DateTime d) => _iso.format(d);

  static String relativeFromNow(DateTime d) {
    final now = DateTime.now();
    final diff = d.difference(now);
    final days = diff.inDays;
    if (days == 0) {
      if (diff.isNegative) return 'just now';
      return 'today';
    }
    if (days < 0) {
      final ago = days.abs();
      if (ago == 1) return 'yesterday';
      if (ago < 7) return '$ago days ago';
      if (ago < 30) return '${(ago / 7).floor()} week(s) ago';
      if (ago < 365) return '${(ago / 30).floor()} month(s) ago';
      return '${(ago / 365).floor()} year(s) ago';
    }
    if (days == 1) return 'tomorrow';
    if (days < 7) return 'in $days days';
    if (days < 30) return 'in ${(days / 7).floor()} week(s)';
    if (days < 365) return 'in ${(days / 30).floor()} month(s)';
    return 'in ${(days / 365).floor()} year(s)';
  }

  static String daysRemainingLabel(DateTime endDate) {
    final diff = endDate.difference(DateTime.now()).inDays;
    if (diff > 1) return '$diff days left';
    if (diff == 1) return '1 day left';
    if (diff == 0) return 'Ends today';
    return 'Expired ${diff.abs()} day${diff.abs() == 1 ? '' : 's'} ago';
  }

  static String greetingForHour([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
