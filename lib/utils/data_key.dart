import 'package:intl/intl.dart';
class DataKey {
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
  static String formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString.split('T')[1].substring(0, 5);
    }
  }
  static bool shouldCacheTask(DateTime taskDate) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 7));
    final end = now.add(const Duration(days: 7));
    return taskDate.isAfter(start) && taskDate.isBefore(end);
  }
}
