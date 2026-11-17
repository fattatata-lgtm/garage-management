import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _numFmt = NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: 0);

/// "Rp1.250.000"
String rp(num? n) => 'Rp${_numFmt.format((n ?? 0).round())}';

/// "1.250.000" (tanpa Rp)
String num0(num? n) => _numFmt.format((n ?? 0).round());

/// Ringkas untuk kartu kecil: Rp1,2 jt / Rp3,4 M
String rpShort(num n) {
  final a = n.abs();
  String f(double v, String unit) {
    final s = v.toStringAsFixed(1).replaceAll('.', ',');
    return 'Rp${s.endsWith(',0') ? s.substring(0, s.length - 2) : s} $unit';
  }

  if (a >= 1e9) return f(n / 1e9, 'M');
  if (a >= 1e6) return f(n / 1e6, 'jt');
  return rp(n);
}

String fmtDate(DateTime? d) => d == null ? '-' : DateFormat('dd MMM yyyy', 'id_ID').format(d);
String fmtDateTime(DateTime? d) => d == null ? '-' : DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(d);
String fmtShort(DateTime? d) => d == null ? '-' : DateFormat('dd MMM', 'id_ID').format(d);

/// Tanggal terpilih + jam sekarang, dalam UTC ISO (agar tidak bergeser hari di server).
String toApiDate(DateTime d) {
  final now = DateTime.now();
  return DateTime(d.year, d.month, d.day, now.hour, now.minute).toUtc().toIso8601String();
}

String toApiNoon(DateTime d) => DateTime(d.year, d.month, d.day, 12).toUtc().toIso8601String();
String startOfDayApi(DateTime d) => DateTime(d.year, d.month, d.day).toUtc().toIso8601String();
String endOfDayApi(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59, 999).toUtc().toIso8601String();

String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// Ambil angka dari teks berformat ("1.250.000" -> 1250000)
int parseRp(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Memformat input angka dengan pemisah ribuan saat mengetik.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final text = _numFmt.format(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Teks angka berformat untuk mengisi TextEditingController ("" bila 0).
String rpText(num? n) => (n == null || n == 0) ? '' : num0(n);

String initialOf(String? s) {
  final t = (s ?? '').trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}
