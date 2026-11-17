import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/launchers.dart';
import 'package:provider/provider.dart';

import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/settings_provider.dart';
import '../../print/pdf_docs.dart';
import '../../print/printer.dart';
import '../../print/receipts.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class SalesDetailScreen extends StatefulWidget {
  const SalesDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<SalesDetailScreen> createState() => _SalesDetailScreenState();
}

class _SalesDetailScreenState extends State<SalesDetailScreen> {
  bool _busy = false;

  Future<void> _wa(Sale s) async {
    setState(() => _busy = true);
    try {
      final d = await Api.I.get('/sales/${s.id}/whatsapp-message');
      final m = Map<String, dynamic>.from(d as Map);
      final phone = m['phone'] as String?;
      if (phone == null || phone.isEmpty) {
        if (mounted) toast(context, 'Pelanggan umum tidak memiliki nomor WhatsApp.', error: true);
      } else {
        final ok = await openWhatsApp(phone, (m['message'] as String?) ?? '');
        if (!ok && mounted) toast(context, 'Tidak dapat membuka WhatsApp.', error: true);
      }
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Sale s) async {
    final ok = await confirmDialog(context,
        title: 'Hapus transaksi?',
        message: 'Transaksi ${s.invoiceNo} akan dihapus dan stok sparepart yang terjual dikembalikan. Tindakan ini tidak dapat dibatalkan.',
        okLabel: 'Hapus',
        danger: true);
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await Api.I.delete('/sales/${s.id}');
      Bus.bump();
      if (!mounted) return;
      toast(context, 'Transaksi ${s.invoiceNo} dihapus.');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Penjualan')),
      body: AsyncBody<Sale>(
        loader: () => Api.I.one('/sales/${widget.id}', Sale.fromJson),
        builder: (context, s, reload) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const IconTile(Icons.receipt_long_rounded, color: C.ok, bg: C.okBg, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(fmtDateTime(s.date), style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const StatusChip('SELESAI', label: 'Lunas'),
                    ],
                  ),
                  const Divider(height: 24),
                  InfoRow('Pelanggan', s.customerName),
                  if (s.customer != null) InfoRow('No. HP', s.customer!.phone),
                ],
              ),
            ),
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),
                  for (final it in s.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                Text('${it.qty} × ${rp(it.price)}', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(rp(it.price * it.qty), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  const Divider(height: 22),
                  SummaryRow('Subtotal', rp(s.subtotal)),
                  if (s.discountAmount > 0) SummaryRow(s.discount != null ? 'Diskon (${s.discount!.name})' : 'Diskon', '-${rp(s.discountAmount)}', color: C.ok),
                  SummaryRow('Pajak', rp(s.taxAmount)),
                  const Divider(height: 22),
                  SummaryRow('Total', rp(s.total), bold: true, big: true, color: C.brandOf(context)),
                  SummaryRow('Dibayar', rp(s.paid)),
                  SummaryRow('Kembalian', rp(s.change)),
                ],
              ),
            ),
            ActionButton(
              label: 'Cetak Invoice (A4 / PDF)',
              icon: Icons.description_rounded,
              onPressed: () => PrintService.invoice(context, context.read<SettingsProvider>(), salesInvoiceData(s)),
            ),
            const SizedBox(height: 10),
            ActionButton(
              label: 'Struk Thermal',
              icon: Icons.print_rounded,
              kind: BtnKind.secondary,
              onPressed: () => PrintService.thermal(context, context.read<SettingsProvider>(), (shop) => buildSalesReceipt(s, shop), title: 'Struk Penjualan'),
            ),
            const SizedBox(height: 10),
            ActionButton(label: 'Kirim Struk via WhatsApp', icon: Icons.chat_rounded, kind: BtnKind.success, busy: _busy, onPressed: () => _wa(s)),
            const SizedBox(height: 10),
            ActionButton(label: 'Hapus Transaksi', icon: Icons.delete_outline_rounded, kind: BtnKind.danger, onPressed: _busy ? null : () => _delete(s)),
          ],
        ),
      ),
    );
  }
}
