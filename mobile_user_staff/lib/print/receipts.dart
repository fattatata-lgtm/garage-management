import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../core/models.dart';
import 'escpos.dart';

/// Identitas bengkel untuk kop struk/invoice + lebar kertas thermal.
class ShopInfo {
  ShopInfo({required this.name, this.address, this.phone, this.logoUrl, required this.paperMm});
  final String name;
  final String? address;
  final String? phone;
  final String? logoUrl; // URL penuh
  final int paperMm; // 58 / 80

  int get cols => paperMm == 58 ? 32 : 48;
}

final Map<String, Raster> _logoCache = {};
final Map<String, Uint8List> _logoBytesCache = {};

/// Unduh logo (null bila gagal).
Future<Uint8List?> fetchLogoBytes(String? url) async {
  if (url == null || url.isEmpty) return null;
  if (_logoBytesCache.containsKey(url)) return _logoBytesCache[url];
  try {
    final r = await Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 10)))
        .get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final b = Uint8List.fromList(r.data ?? const []);
    if (b.isEmpty) return null;
    _logoBytesCache[url] = b;
    return b;
  } catch (_) {
    return null;
  }
}

// Kop: logo (bila ada & berhasil dimuat) atau nama bengkel besar, lalu alamat & telepon.
Future<void> _header(EscPos p, ShopInfo s) async {
  var logoPrinted = false;
  if (s.logoUrl != null && s.logoUrl!.isNotEmpty) {
    try {
      final maxW = p.cols <= 32 ? 384 : 512;
      final key = '${s.logoUrl}|$maxW';
      if (!_logoCache.containsKey(key)) {
        final bytes = await fetchLogoBytes(s.logoUrl);
        if (bytes != null) _logoCache[key] = await loadRaster(bytes, maxWidth: maxW);
      }
      final r = _logoCache[key];
      if (r != null) {
        p.align('center').image(r).align('left');
        logoPrinted = true;
      }
    } catch (_) {/* logo gagal: lanjut tanpa logo */}
  }
  if (!logoPrinted && s.name.isNotEmpty) p.big(s.name);
  if ((s.address ?? '').isNotEmpty) p.center(s.address!);
  if ((s.phone ?? '').isNotEmpty) p.center('Telp: ${s.phone}');
  p.divider();
}

void _title(EscPos p, String text, [String? sub]) {
  p.align('center').bold(true).size(1, 2).line(text).reset().align('center');
  if (sub != null) p.wrap(sub);
  p.align('left').divider();
}

void _section(EscPos p, String text) => p.bold(true).line(text).bold(false);

void _totalBlock(EscPos p, num total, num paid, num change, bool billing) {
  p.divider();
  p.bold(true).size(1, 2).pair(billing ? 'TOTAL TAGIHAN' : 'TOTAL', rp(total)).reset();
  if (!billing) {
    p.pair('Dibayar', rp(paid));
    p.pair('Kembalian', rp(change));
  }
}

String _vehicleLine(Service s) {
  final v = s.vehicle;
  return '${v?.plateNumber ?? '-'} - ${v?.model?.brand ?? ''} ${v?.model?.model ?? ''}'.trim();
}

/// Struk service. billing=true -> "TAGIHAN SERVICE" (belum dibayar), false -> "STRUK SERVICE" (lunas).
Future<EscPos> buildServiceReceipt(Service svc, ShopInfo shop, {bool billing = false}) async {
  final p = EscPos(shop.cols);
  final narrow = p.cols <= 32;
  await _header(p, shop);

  _title(p, billing ? 'TAGIHAN SERVICE' : 'STRUK SERVICE', 'No. ${svc.invoiceNo} - ${fmtDate(svc.date)}');
  p.wrap('Kendaraan: ${_vehicleLine(svc)}');
  p.wrap('Pemilik: ${svc.ownerName}');
  p.divider();

  _section(p, 'Detail Service');
  if (svc.details.isNotEmpty) {
    for (var i = 0; i < svc.details.length; i++) {
      p.entry(i + 1, svc.details[i].name, rp(svc.details[i].cost));
    }
  } else {
    p.line('-');
  }
  p.divider();

  _section(p, 'Sparepart Digunakan');
  if (svc.parts.isNotEmpty) {
    for (var i = 0; i < svc.parts.length; i++) {
      final x = svc.parts[i];
      p.entry(i + 1, x.name, rp(x.price * x.qty), '${x.qty} x ${rp(x.price)}');
    }
  } else {
    p.line('-');
  }
  p.divider();

  p.pair(narrow ? 'Total Jasa' : 'Total Biaya Service', rp(svc.jasaTotal));
  p.pair(narrow ? 'Total Sparepart' : 'Total Biaya Sparepart', rp(svc.partsTotal));
  p.pair('Subtotal', rp(svc.subtotal));
  if (svc.discountAmount > 0) p.pair('Diskon', '-${rp(svc.discountAmount)}');
  if (svc.taxAmount > 0) p.pair('Pajak', rp(svc.taxAmount));
  _totalBlock(p, svc.total, svc.paid, svc.change, billing);
  p.divider();
  if (billing) {
    p.center('Mohon lakukan pembayaran di kasir.');
  } else {
    p.center('LUNAS');
    p.center('Terima kasih atas kepercayaan Anda.');
  }
  p.cut();
  return p;
}

Future<EscPos> buildSalesReceipt(Sale sale, ShopInfo shop) async {
  final p = EscPos(shop.cols);
  await _header(p, shop);
  final when = sale.date == null ? '-' : DateFormat('dd/MM/yyyy HH.mm.ss').format(sale.date!);
  _title(p, 'STRUK PENJUALAN', 'No. ${sale.invoiceNo} - $when');
  p.wrap('Pembeli: ${sale.customerName}');
  p.divider();

  _section(p, 'Detail Penjualan');
  for (var i = 0; i < sale.items.length; i++) {
    final it = sale.items[i];
    p.entry(i + 1, it.name, rp(it.price * it.qty), '${it.qty} x ${rp(it.price)}');
  }
  p.divider();

  p.pair('Subtotal', rp(sale.subtotal));
  if (sale.discountAmount > 0) p.pair('Diskon', '-${rp(sale.discountAmount)}');
  if (sale.taxAmount > 0) p.pair('Pajak', rp(sale.taxAmount));
  _totalBlock(p, sale.total, sale.paid, sale.change, false);
  p.divider();
  p.center('Terima kasih telah berbelanja.');
  p.cut();
  return p;
}

/// Bukti service diterima (saat kendaraan masuk).
Future<EscPos> buildReceivedReceipt(Service svc, ShopInfo shop) async {
  final p = EscPos(shop.cols);
  final v = svc.vehicle;
  await _header(p, shop);
  _title(p, 'BUKTI SERVICE DITERIMA', 'No. ${svc.invoiceNo}');
  p.wrap('Kendaraan: ${v?.model?.brand ?? ''} ${v?.model?.model ?? ''} (${v?.model?.year ?? '-'})');
  p.bold(true).wrap('No. Plat: ${v?.plateNumber ?? '-'}').bold(false);
  p.wrap('Pemilik: ${svc.ownerName}');
  if ((v?.customer?.phone ?? '').isNotEmpty) p.wrap('Telp: ${v!.customer!.phone}');
  p.wrap('Teknisi: ${svc.technician?.name ?? '-'}');
  p.wrap('Tanggal: ${fmtDate(svc.date)}');
  p.wrap('Keluhan: ${svc.complaint.isEmpty ? '-' : svc.complaint}');
  p.divider();
  p.center('Simpan bukti ini untuk pengambilan kendaraan.');
  p.cut();
  return p;
}

/// Work order untuk teknisi.
Future<EscPos> buildWorkOrderReceipt(Service svc, ShopInfo shop) async {
  final p = EscPos(shop.cols);
  _title(p, 'WORK ORDER', 'No. ${svc.invoiceNo}');
  p.wrap('Kendaraan: ${_vehicleLine(svc)}');
  p.wrap('Teknisi: ${svc.technician?.name ?? '-'}');
  p.wrap('KM: ${svc.km ?? '-'}');
  p.wrap('Keluhan: ${svc.complaint.isEmpty ? '-' : svc.complaint}');
  p.divider();

  _section(p, 'Jasa Dikerjakan');
  if (svc.details.isNotEmpty) {
    for (var i = 0; i < svc.details.length; i++) {
      p.entry(i + 1, svc.details[i].name);
      final d = svc.details[i].description;
      if (d != null && d.isNotEmpty) p.note(d);
    }
  } else {
    p.line('-');
  }
  p.divider();

  _section(p, 'Sparepart Dipakai');
  if (svc.parts.isNotEmpty) {
    for (var i = 0; i < svc.parts.length; i++) {
      p.entry(i + 1, svc.parts[i].name, 'x${svc.parts[i].qty}');
    }
  } else {
    p.line('-');
  }
  if (svc.internalNote.isNotEmpty) {
    p.divider();
    _section(p, 'Catatan Internal');
    p.wrap(svc.internalNote);
  }
  p.cut();
  return p;
}

/// Struk uji: penggaris lebar kolom + contoh rata kiri/kanan/tengah + teks tebal & besar.
Future<EscPos> buildTestReceipt(ShopInfo shop) async {
  final p = EscPos(shop.cols);
  await _header(p, shop);
  p.align('center').bold(true).line('TES CETAK PRINTER').bold(false).align('left');
  p.divider('=');
  p.line(('1234567890' * 5).substring(0, p.cols));
  p.line('Lebar kertas: ${p.cols} karakter');
  p.pair('Rata kiri', 'rata kanan');
  p.center('Rata tengah');
  p.bold(true).line('Teks tebal').bold(false);
  p.size(2, 2).line('Besar').reset();
  p.divider();
  p.entry(1, 'Contoh nama item yang cukup panjang', rp(150000), '2 x ${rp(75000)}');
  p.bold(true).size(1, 2).pair('TOTAL', rp(150000)).reset();
  p.divider('=');
  p.center('Printer siap digunakan.');
  p.cut();
  return p;
}
