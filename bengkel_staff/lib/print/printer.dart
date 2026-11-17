import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pdf/pdf.dart';

import '../core/api_client.dart';
import '../core/settings_provider.dart';
import '../core/storage.dart';
import '../widgets/common.dart';
import 'escpos.dart';
import 'pdf_docs.dart';
import 'receipts.dart';

/// Cara mengirim struk thermal dari HP.
enum PrintMode { auto, bluetooth, lan, server, pdf }

extension PrintModeX on PrintMode {
  String get label => switch (this) {
        PrintMode.auto => 'Ikuti pengaturan server',
        PrintMode.bluetooth => 'Bluetooth (printer thermal)',
        PrintMode.lan => 'Jaringan WiFi/LAN (IP:port)',
        PrintMode.server => 'Lewat server (printer komputer kasir)',
        PrintMode.pdf => 'Dialog cetak / simpan PDF',
      };

  String get desc => switch (this) {
        PrintMode.auto => 'Memakai mode printer dari Admin > Pengaturan. Bila server memakai printer jaringan/komputer, struk dikirim lewat server; selain itu lewat PDF.',
        PrintMode.bluetooth => 'Kirim langsung ke printer thermal Bluetooth (BLE), mis. Rongta RPP02N.',
        PrintMode.lan => 'Kirim langsung dari HP ke printer jaringan (port 9100) di WiFi yang sama.',
        PrintMode.server => 'Server mengirim ke printer yang diatur di Pengaturan Aplikasi (jaringan/komputer server).',
        PrintMode.pdf => 'Tanpa printer thermal: tampilkan dialog cetak Android atau simpan sebagai PDF.',
      };
}

class PrinterConfig {
  PrinterConfig._();
  static PrintMode get mode => PrintMode.values.firstWhere((m) => m.name == Store.getString('print.mode'), orElse: () => PrintMode.auto);
  static Future<void> setMode(PrintMode m) => Store.setString('print.mode', m.name);

  /// 0 = ikuti server, 58, atau 80
  static int get paper => int.tryParse(Store.getString('print.paper') ?? '') ?? 0;
  static Future<void> setPaper(int v) => Store.setString('print.paper', v == 0 ? null : '$v');

  static String? get bleId => Store.getString('print.bleId');
  static String? get bleName => Store.getString('print.bleName');
  static Future<void> setBle(String? id, String? name) async {
    await Store.setString('print.bleId', id);
    await Store.setString('print.bleName', name);
  }

  static String get lanHost => Store.getString('print.lanHost') ?? '';
  static int get lanPort => int.tryParse(Store.getString('print.lanPort') ?? '') ?? 9100;
  static Future<void> setLan(String host, int port) async {
    await Store.setString('print.lanHost', host.trim());
    await Store.setString('print.lanPort', '$port');
  }
}

class PrintException implements Exception {
  PrintException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _msg(Object e) {
  if (e is PrintException) return e.message;
  if (e is ApiException) return e.message;
  if (e is SocketException) return 'Tidak dapat terhubung ke printer (${e.message}).';
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}

class PrintService {
  PrintService._();

  static int paperMm(SettingsProvider st) {
    final o = PrinterConfig.paper;
    if (o == 58 || o == 80) return o;
    return RegExp('58').hasMatch(st.printerType ?? '') ? 58 : 80;
  }

  static ShopInfo shop(SettingsProvider st) =>
      ShopInfo(name: st.businessName, address: st.address, phone: st.phone, logoUrl: st.logo.isEmpty ? null : st.logo, paperMm: paperMm(st));

  /// true bila struk dikirim sebagai byte ESC/POS ke printer (bukan PDF).
  static bool isRaw(SettingsProvider st) {
    switch (PrinterConfig.mode) {
      case PrintMode.bluetooth:
      case PrintMode.lan:
      case PrintMode.server:
        return true;
      case PrintMode.pdf:
        return false;
      case PrintMode.auto:
        final c = st.printerConnection;
        if (c == 'NETWORK' || c == 'SYSTEM') return true;
        if (c == 'BLUETOOTH' && PrinterConfig.bleId != null) return true;
        return false;
    }
  }

  static Future<void> sendRaw(Uint8List bytes, SettingsProvider st) async {
    var mode = PrinterConfig.mode;
    if (mode == PrintMode.auto) {
      mode = st.printerConnection == 'BLUETOOTH' ? PrintMode.bluetooth : PrintMode.server;
    }
    switch (mode) {
      case PrintMode.bluetooth:
        return _sendBle(bytes);
      case PrintMode.lan:
        return _sendLan(bytes);
      case PrintMode.server:
        await Api.I.post('/print/raw', body: {'data': base64Encode(bytes)});
        return;
      default:
        throw PrintException('Mode printer adalah dialog cetak PDF.');
    }
  }

  /// Cetak struk thermal; bila printer gagal, tampilkan pratinjau PDF (cadangan).
  static Future<void> thermal(
    BuildContext context,
    SettingsProvider st,
    Future<EscPos> Function(ShopInfo shop) build, {
    required String title,
  }) async {
    final shopInfo = shop(st);
    try {
      final p = await build(shopInfo);
      if (isRaw(st)) {
        try {
          await sendRaw(p.build(), st);
          if (context.mounted) toast(context, 'Dikirim ke printer.');
          return;
        } catch (e) {
          if (context.mounted) toast(context, 'Printer thermal: ${_msg(e)} Dialihkan ke pratinjau PDF.', error: true);
        }
      }
      final bytes = await buildReceiptPreviewPdf(p.preview, shopInfo.paperMm);
      await showPdf(bytes, title, format: PdfPageFormat(shopInfo.paperMm * PdfPageFormat.mm, 200 * PdfPageFormat.mm, marginAll: 3 * PdfPageFormat.mm));
    } catch (e) {
      if (context.mounted) toast(context, _msg(e), error: true);
    }
  }

  /// Tampilkan struk yang sudah disusun sebagai PDF (tanpa printer thermal).
  static Future<void> thermalPreviewOnly(BuildContext context, EscPos p, int paperMm, String title) async {
    try {
      final bytes = await buildReceiptPreviewPdf(p.preview, paperMm);
      await showPdf(bytes, title, format: PdfPageFormat(paperMm * PdfPageFormat.mm, 200 * PdfPageFormat.mm, marginAll: 3 * PdfPageFormat.mm));
    } catch (e) {
      if (context.mounted) toast(context, _msg(e), error: true);
    }
  }

  /// Invoice A4 (PDF): pratinjau / cetak / simpan.
  static Future<void> invoice(BuildContext context, SettingsProvider st, InvoiceData data) async {
    try {
      final bytes = await buildInvoicePdf(data, shop(st));
      await showPdf(bytes, '${data.title} ${data.invoiceNo}');
    } catch (e) {
      if (context.mounted) toast(context, 'Gagal membuat PDF: ${_msg(e)}', error: true);
    }
  }
}

// ======================================================================= Transport

Future<void> _sendLan(Uint8List bytes) async {
  if (kIsWeb) throw PrintException('Cetak jaringan langsung tidak tersedia di browser. Gunakan mode "Lewat server" atau PDF.');
  final host = PrinterConfig.lanHost;
  if (host.isEmpty) throw PrintException('Alamat IP printer belum diisi di Pengaturan Printer.');
  final socket = await Socket.connect(host, PrinterConfig.lanPort, timeout: const Duration(seconds: 6));
  try {
    socket.add(bytes);
    await socket.flush();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  } finally {
    await socket.close();
    socket.destroy();
  }
}

String bleNameOf(ScanResult r) {
  final n = r.device.platformName;
  return n.isNotEmpty ? n : r.advertisementData.advName;
}

Future<void> _sendBle(Uint8List bytes) async {
  if (kIsWeb) throw PrintException('Bluetooth langsung tidak tersedia di browser. Gunakan HP Android.');
  final id = PrinterConfig.bleId;
  if (id == null) throw PrintException('Printer Bluetooth belum dipilih. Buka Menu > Pengaturan Printer.');
  if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
    throw PrintException('Bluetooth HP belum aktif.');
  }
  final dev = BluetoothDevice.fromId(id);
  try {
    await dev.connect(timeout: const Duration(seconds: 12));
  } catch (_) {
    throw PrintException('Tidak dapat terhubung ke printer. Pastikan printer menyala dan dekat dengan HP.');
  }
  try {
    final services = await dev.discoverServices();
    BluetoothCharacteristic? ch;
    bool skip(BluetoothService s) {
      final u = s.uuid.toString().toLowerCase();
      return u == '1800' || u == '1801' || u.startsWith('00001800') || u.startsWith('00001801');
    }

    for (final s in services.where((s) => !skip(s))) {
      for (final c in s.characteristics) {
        if (c.properties.writeWithoutResponse) {
          ch = c;
          break;
        }
      }
      if (ch != null) break;
    }
    if (ch == null) {
      for (final s in services.where((s) => !skip(s))) {
        for (final c in s.characteristics) {
          if (c.properties.write) {
            ch = c;
            break;
          }
        }
        if (ch != null) break;
      }
    }
    if (ch == null) {
      throw PrintException('Printer terhubung, tetapi jalur tulis data tidak ditemukan. Pastikan memilih printer yang benar.');
    }

    final noResp = ch.properties.writeWithoutResponse;
    var size = math.max(20, math.min(100, dev.mtuNow - 3));
    var o = 0;
    while (o < bytes.length) {
      final end = math.min(bytes.length, o + size);
      final part = bytes.sublist(o, end);
      try {
        await ch.write(part, withoutResponse: noResp);
      } catch (e) {
        if (size > 20) {
          size = 20;
          await Future<void>.delayed(const Duration(milliseconds: 60));
          continue;
        }
        rethrow;
      }
      o = end;
      await Future<void>.delayed(Duration(milliseconds: size >= 100 ? 15 : 25));
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  } finally {
    try {
      await dev.disconnect();
    } catch (_) {}
  }
}
