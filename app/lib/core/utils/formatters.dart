import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    symbol: 'Br ',
    decimalDigits: 2,
  );

  static String currency(double value) => _currency.format(value);

  static String units(int value) => '$value units';

  static String liters(double liters) {
    if (liters == liters.roundToDouble()) {
      return '${liters.toInt()}L';
    }

    return '${liters.toStringAsFixed(1)}L';
  }

  static String date(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  static String shortDate(DateTime value) => DateFormat('dd MMM').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('dd MMM yyyy • HH:mm').format(value);
}
