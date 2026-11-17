import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import 'sparepart_form_screen.dart';

class SparepartDetailScreen extends StatefulWidget {
  const SparepartDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<SparepartDetailScreen> createState() => _SparepartDetailScreenState();
}

class _SparepartDetailScreenState extends State<SparepartDetailScreen> {
  final _key = GlobalKey<AsyncBodyState<Sparepart>>();

  Future<void> _move(Sparepart sp, String direction) async {
    final qty = TextEditingController();
    final note = TextEditingController();
    final masuk = direction == 'MASUK';

    // Stok masuk: supplier bawaan sparepart terpilih otomatis (masih bisa diganti / dikosongkan), sama seperti website.
    Supplier? supplier = masuk ? sp.supplier : null;
    var suppliers = <Supplier>[];
    if (masuk) {
      try {
        suppliers = await Api.I.list('/suppliers', Supplier.fromJson);
      } on ApiException catch (e) {
        if (mounted) toast(context, e.message, error: true);
      }
    }
    if (!mounted) {
      qty.dispose();
      note.dispose();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(masuk ? 'Stok Masuk' : 'Stok Keluar', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: StatefulBuilder(
          builder: (context, setDlg) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (masuk) ...[
                  FieldTile(
                    label: 'Supplier (opsional)',
                    icon: Icons.local_shipping_rounded,
                    value: supplier?.name ?? 'Tanpa Supplier',
                    trailing: supplier != null
                        ? GestureDetector(
                            onTap: () => setDlg(() => supplier = null),
                            child: const Icon(Icons.close_rounded, size: 20),
                          )
                        : const Icon(Icons.keyboard_arrow_down_rounded),
                    onTap: () async {
                      final r = await pickSupplier(context, suppliers);
                      if (r != null) setDlg(() => supplier = r.id == -1 ? null : r);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                LabeledField('Jumlah', TextField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: deco(null, icon: masuk ? Icons.add_box_rounded : Icons.indeterminate_check_box_rounded, hint: masuk ? 'Contoh: 10' : 'Maks. ${sp.stock}'),
                )),
                const SizedBox(height: 12),
                LabeledField('Keterangan (opsional)', TextField(controller: note, decoration: deco(null, hint: 'Isi keterangan jika perlu', icon: Icons.notes_rounded))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: masuk ? C.ok : C.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final q = int.tryParse(qty.text) ?? 0;
    final n = note.text.trim();
    // Dialog masih beranimasi menutup saat showDialog selesai; controller baru dibuang setelahnya.
    Future.delayed(const Duration(milliseconds: 500), () {
      qty.dispose();
      note.dispose();
    });
    if (ok != true) return;
    if (!mounted) return;
    if (q <= 0) {
      toast(context, 'Jumlah harus lebih dari 0.', error: true);
      return;
    }
    try {
      await Api.I.post('/spareparts/${sp.id}/stock-move', body: {
        'direction': direction,
        'quantity': q,
        'note': n.isEmpty ? null : n,
        if (masuk) 'supplierId': supplier?.id,
      });
      Bus.bump();
      if (mounted) {
        toast(context, masuk ? 'Stok bertambah $q' : 'Stok berkurang $q');
        _key.currentState?.reload();
      }
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _delete(Sparepart sp) async {
    final ok = await confirmDialog(context, title: 'Hapus sparepart?', message: '${sp.name} akan dihapus permanen.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/spareparts/${sp.id}');
      Bus.bump();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message.contains('Foreign') ? 'Sparepart sudah dipakai transaksi dan tidak bisa dihapus.' : e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Sparepart>(
      fullScreen: true,
      key: _key,
      loader: () => Api.I.one('/spareparts/${widget.id}', Sparepart.fromJson),
      builder: (context, sp, reload) {
        final c = C.tone(context, statusColor(sp.status));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Sparepart'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final r = await go<bool>(context, SparepartFormScreen(sparepart: sp));
                  if (r == true) reload();
                },
              ),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.danger), onPressed: () => _delete(sp)),
            ],
          ),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(sp.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                        StatusChip(sp.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${sp.code} · ${sp.categoryName}', style: TextStyle(color: C.mutedOf(context))),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: statusBg(sp.status), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Text('${sp.stock}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: c, height: 1)),
                          const SizedBox(width: 10),
                          Expanded(child: Text('unit tersedia\nBatas rendah: ${sp.lowStockThreshold}', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12.5))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    InfoRow('Supplier', sp.supplierName ?? '-'),
                    InfoRow('Harga beli', rp(sp.buyPrice)),
                    InfoRow('Harga jual', rp(sp.sellPrice), bold: true, valueColor: C.brandOf(context)),
                    InfoRow('Margin / unit', rp(sp.sellPrice - sp.buyPrice), valueColor: C.ok),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(child: ActionButton(label: 'Stok Masuk', icon: Icons.add_rounded, kind: BtnKind.success, onPressed: () => _move(sp, 'MASUK'))),
                  const SizedBox(width: 12),
                  Expanded(child: ActionButton(label: 'Stok Keluar', icon: Icons.remove_rounded, kind: BtnKind.danger, onPressed: () => _move(sp, 'KELUAR'))),
                ],
              ),
              const SectionTitle('Riwayat Stok'),
              if (sp.history.isEmpty)
                AppCard(child: Center(child: Text('Belum ada riwayat stok', style: TextStyle(color: C.mutedOf(context)))))
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < sp.history.length; i++) ...[
                        HistoryRow(item: sp.history[i]),
                        if (i < sp.history.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Satu baris riwayat stok (dipakai juga di layar Riwayat Stok).
class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.item, this.showName = false});
  final StockHistory item;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final h = item;
    final c = C.tone(context, statusColor(h.direction));
    final src = switch (h.source) {
      'SERVICE' => 'Service',
      'PENJUALAN' => 'Penjualan',
      _ => 'Manual',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          IconTile(h.masuk ? Icons.south_west_rounded : Icons.north_east_rounded, color: c, bg: statusBg(h.direction), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(showName && h.sparepartName != null ? h.sparepartName! : '$src${h.refInvoice != null ? ' · ${h.refInvoice}' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(
                  '${showName ? '$src · ' : ''}${h.note ?? fmtDateTime(h.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: C.mutedOf(context), fontSize: 11.5),
                ),
                if (h.note != null) Text(fmtDateTime(h.createdAt), style: TextStyle(color: C.mutedOf(context), fontSize: 11)),
                if (h.supplierName != null)
                  Text('Supplier: ${h.supplierName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
              ],
            ),
          ),
          Text('${h.masuk ? '+' : '-'}${h.quantity}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: c)),
        ],
      ),
    );
  }
}
