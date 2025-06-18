import 'package:intl/intl.dart';

class DateUtils {
  static DateTime? parseDate(String dateStr,
      {String format = 'd MMM yyyy', String locale = 'id_ID'}) {
    try {
      return DateFormat(format, locale).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  static String formatDate(DateTime? date,
      {String format = 'EEEE, d MMMM yyyy', String locale = 'id_ID'}) {
    if (date == null) return '';
    return DateFormat(format, locale).format(date);
  }
}
