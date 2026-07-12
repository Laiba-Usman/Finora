import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy hh:mm a').format(date);
  }

  static String toYearMonthString(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }
}
