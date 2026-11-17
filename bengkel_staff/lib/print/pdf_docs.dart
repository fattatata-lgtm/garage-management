import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../core/models.dart';
import 'escpos.dart' show toAscii;
import 'receipts.dart';

final NumberFormat _money2 = NumberFormat('#,##0.00', 'id_ID');
String _t(Object? v) => toAscii(v); // font bawaan PDF hanya mendukung Latin dasar

String longDate(DateTime? d) {
  final dt = d ?? DateTime.now();
  return '${DateFormat('EEEE', 'id_ID').format(dt)}, ${dt.day} ${DateFormat('MMM', 'id_ID').format(dt)} ${dt.year}';
}

// ============================================================== Data invoice

class InvItem {
  InvItem({required this.name, this.description, this.qty = 1, this.uom = '', required this.price});
  final String name;
  final String? description;
  final int qty;
  final String uom;
  final num price;
}

class InvRow {
  InvRow({this.no, required this.label, required this.value});
  final int? no;
  final String label;
  final num value;
}

class InvoiceData {
  InvoiceData({
    required this.title,
    required this.invoiceNo,
    required this.date,
    required this.billTo,
    this.toLine,
    this.tipeKendaraan,
    this.partsTitle,
    this.parts = const [],
    this.jasaTitle,
    this.jasa = const [],
    this.summaryTitle = 'JUMLAH TOTAL BIAYA',
    required this.rows,
    required this.grand,
    this.after = const [],
    this.note = '',
  });
  final String title;
  final String invoiceNo;
  final DateTime? date;
  final String billTo;
  final String? toLine;
  final String? tipeKendaraan;
  final String? partsTitle;
  final List<InvItem> parts;
  final String? jasaTitle;
  final List<InvItem> jasa;
  final String summaryTitle;
  final List<InvRow> rows;
  final num grand;
  final List<InvRow> after;
  final String note;
}

/// Data invoice/tagihan service (sama dengan printBilling versi web).
InvoiceData serviceInvoiceData(Service svc, {required bool tagihan}) {
  final vm = svc.vehicle?.model;
  final tipe = vm == null ? '' : '${vm.brand} ${vm.model} (${vm.year})'.toUpperCase();
  final jasa = svc.details.map((d) => InvItem(name: d.name, description: d.description, price: d.cost)).toList();
  final parts = svc.parts.map((p) => InvItem(name: p.name, qty: p.qty, uom: 'pcs', price: p.price)).toList();
  final rows = <InvRow>[];
  if (parts.isNotEmpty) rows.add(InvRow(no: rows.length + 1, label: 'Biaya Suku Cadang', value: svc.partsTotal));
  if (jasa.isNotEmpty) rows.add(InvRow(no: rows.length + 1, label: 'Biaya Jasa Service', value: svc.jasaTotal));
  if (svc.discountAmount > 0) {
    rows.add(InvRow(label: svc.discount != null ? 'Diskon (${svc.discount!.name})' : 'Diskon', value: -svc.discountAmount));
  }
  if (svc.taxAmount > 0) rows.add(InvRow(label: 'Pajak', value: svc.taxAmount));
  return InvoiceData(
    title: tagihan ? 'Tagihan Service' : 'Invoice Service',
    invoiceNo: svc.invoiceNo,
    date: svc.date,
    billTo: svc.ownerName,
    toLine: '${svc.plate}, $tipe',
    tipeKendaraan: tipe,
    partsTitle: 'BIAYA SUKU CADANG',
    parts: parts,
    jasaTitle: 'BIAYA JASA SERVICE',
    jasa: jasa,
    rows: rows,
    grand: svc.total,
    after: tagihan ? const [] : [InvRow(label: 'Dibayar', value: svc.paid), InvRow(label: 'Kembalian', value: svc.change)],
    note: tagihan ? '' : 'LUNAS - Terima kasih atas kepercayaan Anda.',
  );
}

InvoiceData salesInvoiceData(Sale sale) {
  final rows = <InvRow>[InvRow(label: 'Subtotal', value: sale.subtotal)];
  if (sale.discountAmount > 0) {
    rows.add(InvRow(label: sale.discount != null ? 'Diskon (${sale.discount!.name})' : 'Diskon', value: -sale.discountAmount));
  }
  if (sale.taxAmount > 0) rows.add(InvRow(label: 'Pajak', value: sale.taxAmount));
  return InvoiceData(
    title: 'Invoice Penjualan',
    invoiceNo: sale.invoiceNo,
    date: sale.date,
    billTo: sale.customerName,
    toLine: sale.customer?.phone,
    partsTitle: 'DAFTAR BARANG',
    parts: sale.items.map((i) => InvItem(name: i.name, qty: i.qty, uom: 'pcs', price: i.price)).toList(),
    summaryTitle: 'RINCIAN PEMBAYARAN',
    rows: rows,
    grand: sale.total,
    after: [InvRow(label: 'Dibayar', value: sale.paid), InvRow(label: 'Kembalian', value: sale.change)],
    note: 'LUNAS - Terima kasih atas kepercayaan Anda.',
  );
}

// ============================================================== Widget tabel

const double _fs = 9.5;
pw.TextStyle _st({bool bold = false, double size = _fs}) =>
    pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);

pw.Widget _txt(String s, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      child: pw.Text(_t(s), textAlign: align, style: _st(bold: bold)),
    );

pw.Widget _rpCell(num v, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text('Rp', style: _st(bold: bold)), pw.Text(_money2.format(v), style: _st(bold: bold))],
      ),
    );

pw.Widget _section(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
      child: pw.Text(_t(title), style: _st(bold: true)),
    );

pw.TableRow _headRow(List<String> heads) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: heads.map((h) => _txt(h, bold: true, align: pw.TextAlign.center)).toList(),
    );

pw.Widget _partsTable(String title, List<InvItem> items) {
  final total = items.fold<num>(0, (a, i) => a + i.price * i.qty);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _section(title),
    pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(0.9),
        4: pw.FlexColumnWidth(2.2),
        5: pw.FlexColumnWidth(2.2),
      },
      children: [
        _headRow(['No', 'Deskripsi', 'Qty', 'Sat', 'Harga', 'Jumlah']),
        for (var i = 0; i < items.length; i++)
          pw.TableRow(children: [
            _txt('${i + 1}', align: pw.TextAlign.center),
            _txt(items[i].name),
            _txt('${items[i].qty}', align: pw.TextAlign.center),
            _txt(items[i].uom, align: pw.TextAlign.center),
            _rpCell(items[i].price),
            _rpCell(items[i].price * items[i].qty),
          ]),
        pw.TableRow(children: [
          _txt(''),
          _txt('Jumlah Total', bold: true, align: pw.TextAlign.center),
          _txt(''),
          _txt(''),
          _txt(''),
          _rpCell(total, bold: true),
        ]),
      ],
    ),
  ]);
}

pw.Widget _costTable(String title, List<InvItem> items) {
  final total = items.fold<num>(0, (a, i) => a + i.price);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _section(title),
    pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: const {0: pw.FlexColumnWidth(0.6), 1: pw.FlexColumnWidth(6), 2: pw.FlexColumnWidth(2.4)},
      children: [
        _headRow(['No', 'Deskripsi', 'Biaya']),
        for (var i = 0; i < items.length; i++)
          pw.TableRow(children: [
            _txt('${i + 1}', align: pw.TextAlign.center),
            _txt('${items[i].name}${(items[i].description ?? '').isNotEmpty ? ' - ${items[i].description}' : ''}'),
            _rpCell(items[i].price),
          ]),
        pw.TableRow(children: [_txt(''), _txt('Jumlah', bold: true, align: pw.TextAlign.center), _rpCell(total, bold: true)]),
      ],
    ),
  ]);
}

pw.Widget _summaryTable(InvoiceData d) {
  pw.TableRow line(InvRow r) => pw.TableRow(children: [_txt(r.no?.toString() ?? '', align: pw.TextAlign.center), _txt(r.label), _rpCell(r.value)]);
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    _section(d.summaryTitle),
    pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: const {0: pw.FlexColumnWidth(0.6), 1: pw.FlexColumnWidth(6), 2: pw.FlexColumnWidth(2.4)},
      children: [
        _headRow(['No', 'Deskripsi', 'Biaya']),
        ...d.rows.map(line),
        pw.TableRow(children: [_txt(''), _txt('Total Keseluruhan', bold: true, align: pw.TextAlign.center), _rpCell(d.grand, bold: true)]),
        ...d.after.map(line),
      ],
    ),
  ]);
}

// ============================================================== Invoice A4

Future<Uint8List> buildInvoicePdf(InvoiceData d, ShopInfo shop) async {
  final doc = pw.Document();
  pw.Widget? logo;
  final bytes = await fetchLogoBytes(shop.logoUrl);
  if (bytes != null) {
    try {
      logo = pw.Image(pw.MemoryImage(bytes), height: 48, fit: pw.BoxFit.contain);
    } catch (_) {
      logo = null; // format logo tidak didukung PDF -> pakai nama bengkel
    }
  }
  final logoWidget = logo;
  final contact = [
    if ((shop.phone ?? '').isNotEmpty) 'Telp: ${shop.phone}',
    if ((shop.address ?? '').isNotEmpty) 'Alamat: ${shop.address}',
  ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
    build: (ctx) => [
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue200, width: 1))),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          if (logoWidget != null)
            logoWidget
          else
            pw.Text(_t(shop.name.toUpperCase()), style: _st(bold: true, size: 18)),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [for (final c in contact) pw.Text(_t(c), style: _st(size: 10))]),
          ),
        ]),
      ),
      pw.SizedBox(height: 12),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Invoice', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Text('#${_t(d.invoiceNo)}', style: _st(bold: true, size: 10)),
            ),
            pw.SizedBox(height: 6),
            pw.Text('KEPADA :', style: _st(bold: true, size: 10.5)),
            pw.Text(_t(d.billTo), style: _st(bold: true, size: 11)),
            if ((d.toLine ?? '').isNotEmpty) pw.Text(_t(d.toLine), style: _st(size: 10.5)),
            if ((d.tipeKendaraan ?? '').isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text('TIPE KENDARAAN :', style: _st(bold: true, size: 10.5)),
              pw.Text(_t(d.tipeKendaraan), style: _st(size: 10.5)),
            ],
          ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Tanggal Invoice:', style: _st(bold: true)),
          pw.Text(_t(longDate(d.date)), style: _st()),
          pw.SizedBox(height: 6),
          pw.Text('Jatuh Tempo:', style: _st(bold: true)),
          pw.Text(_t(longDate(d.date)), style: _st()),
        ]),
      ]),
      if (d.parts.isNotEmpty) _partsTable(d.partsTitle ?? 'SPAREPART', d.parts),
      if (d.jasa.isNotEmpty) _costTable(d.jasaTitle ?? 'JASA', d.jasa),
      _summaryTable(d),
      if (d.note.isNotEmpty)
        pw.Padding(padding: const pw.EdgeInsets.only(top: 16), child: pw.Center(child: pw.Text(_t(d.note), style: _st(size: 10)))),
    ],
  ));
  return doc.save();
}

// ============================================================== Laporan

Future<Uint8List> buildReportPdf({
  required String title,
  required List<String> filters,
  required List<(String, String)> summary,
  required List<String> headers,
  required List<List<String>> rows,
  List<double>? flex,
  required ShopInfo shop,
}) async {
  final doc = pw.Document();
  final widths = <int, pw.TableColumnWidth>{
    for (var i = 0; i < headers.length; i++) i: pw.FlexColumnWidth((flex != null && i < flex.length) ? flex[i] : 1),
  };
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(12 * PdfPageFormat.mm),
    build: (ctx) => [
      pw.Text(_t(shop.name.toUpperCase()), style: _st(bold: true, size: 14)),
      pw.SizedBox(height: 4),
      pw.Text(_t(title), style: _st(bold: true, size: 16)),
      for (final f in filters) pw.Text(_t(f), style: _st(size: 10)),
      pw.Text('Dicetak: ${_t(fmtDateTime(DateTime.now()))}', style: _st(size: 9)),
      pw.SizedBox(height: 10),
      pw.Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in summary)
          pw.Container(
            width: 120,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500), borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(_t(s.$1), style: _st(size: 8.5)),
              pw.Text(_t(s.$2), style: _st(bold: true, size: 11)),
            ]),
          ),
      ]),
      pw.SizedBox(height: 12),
      pw.Text('Rincian Data', style: _st(bold: true, size: 11)),
      pw.SizedBox(height: 4),
      if (rows.isEmpty)
        pw.Text('Tidak ada data.', style: _st())
      else
        pw.Table(
          border: pw.TableBorder.all(width: 0.6),
          columnWidths: widths,
          children: [
            _headRow(headers),
            for (final r in rows) pw.TableRow(children: [for (final c in r) _txt(c)]),
          ],
        ),
    ],
  ));
  return doc.save();
}

// ============================================================== Cadangan struk thermal -> PDF

Future<Uint8List> buildReceiptPreviewPdf(List<String> lines, int paperMm) async {
  final doc = pw.Document();
  final w = paperMm * PdfPageFormat.mm;
  const m = 3 * PdfPageFormat.mm;
  final cols = paperMm == 58 ? 32 : 48;
  final fs = (w - 2 * m) / (cols * 0.6);
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat(w, double.infinity, marginAll: m),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [for (final l in lines) pw.Text(l.isEmpty ? ' ' : l, style: pw.TextStyle(font: pw.Font.courier(), fontSize: fs))],
    ),
  ));
  return doc.save();
}

// ============================================================== Buka dialog cetak / simpan PDF

Future<void> showPdf(Uint8List bytes, String name, {PdfPageFormat format = PdfPageFormat.a4}) async {
  await Printing.layoutPdf(name: name, format: format, dynamicLayout: false, onLayout: (_) async => bytes);
}
