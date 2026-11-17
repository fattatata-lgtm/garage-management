import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

String normalizePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
}

/// Buka WhatsApp dengan pesan yang sudah disiapkan backend.
Future<bool> openWhatsApp(String? phone, String message) async {
  if (phone == null || phone.trim().isEmpty) return false;
  final uri = Uri.parse(
      'https://api.whatsapp.com/send?phone=${normalizePhone(phone)}&text=${Uri.encodeComponent(message)}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> callPhone(String phone) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));
  } catch (_) {
    return false;
  }
}

// ----------------------------------------------------------------- Panggil ke Kasir (TTS)

final FlutterTts _tts = FlutterTts();

/// Eja plat nomor per karakter: "N 1234 AB" -> "N, 1 2 3 4, A B"
String spellPlate(String plate) {
  return plate
      .toUpperCase()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p.split('').join(' '))
      .join(', ');
}

String cashierCallText(String plate, String owner) =>
    'Perhatian. Atas nama $owner, dengan nomor polisi ${spellPlate(plate)}, '
    'sudah selesai pengerjaan. Silakan ke kasir untuk melakukan pembayaran.';

Future<void> speakCashierCall(String plate, String owner) async {
  try {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.45);
    await _tts.stop();
    await _tts.speak(cashierCallText(plate, owner));
  } catch (_) {}
}
