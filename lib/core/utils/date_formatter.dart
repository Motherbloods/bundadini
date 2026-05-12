import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toDisplay(DateTime date) =>
      DateFormat('dd MMM yyyy', 'id_ID').format(date);

  static String toDisplayWithDay(DateTime date) =>
      DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);

  static String toShort(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  static String toMonthYear(DateTime date) =>
      DateFormat('MMM yyyy', 'id_ID').format(date);

  static String toIso(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String toFileStamp(DateTime date) =>
      DateFormat('yyyyMMdd').format(date);

  static String toTimeStamp(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);

  static String ageFromDate(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return '$years tahun';
  }

  /// Hitung HPL (Hari Perkiraan Lahir) dari HPHT (Naegele's rule)
  static DateTime? taksiran(DateTime? hpht) {
    if (hpht == null) return null;
    return hpht.add(const Duration(days: 280));
  }

  /// Hitung usia kehamilan dalam minggu dari HPHT
  static int? usiaKehamilanMinggu(DateTime? hpht) {
    if (hpht == null) return null;
    final diff = DateTime.now().difference(hpht).inDays;
    return (diff / 7).floor();
  }

  static String usiaKehamilanFormatted(DateTime? hpht) {
    if (hpht == null) return '-';
    final diff = DateTime.now().difference(hpht).inDays;
    final minggu = (diff / 7).floor();
    final bulan = (minggu / 4.33).floor();
    if (bulan <= 0) return '$minggu minggu';
    return '$minggu minggu ($bulan bulan)';
  }

  static String hplFormatted(DateTime? hpht) {
    if (hpht == null) return '-';
    final hpl = hpht.add(const Duration(days: 280));
    return DateFormat('dd MMM yyyy (EEEE)', 'id_ID').format(hpl);
  }

  static DateTime? parseFlexible(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {}

    try {
      return DateFormat('dd MMM yyyy', 'id_ID').parseStrict(value);
    } catch (_) {}

    try {
      return DateFormat('yyyy-MM-dd').parseStrict(value);
    } catch (_) {}

    return null;
  }
}
