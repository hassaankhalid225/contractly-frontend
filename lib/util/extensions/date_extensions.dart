extension DateExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isPast => isBefore(DateTime.now());
  bool get isFuture => isAfter(DateTime.now());

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  int daysUntil(DateTime other) => other.startOfDay.difference(startOfDay).inDays;

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}
