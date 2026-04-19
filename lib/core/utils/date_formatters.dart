class DateFormatters {
  static String compact(DateTime input) {
    final year = input.year.toString().padLeft(4, '0');
    final month = input.month.toString().padLeft(2, '0');
    final day = input.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  const DateFormatters._();
}
