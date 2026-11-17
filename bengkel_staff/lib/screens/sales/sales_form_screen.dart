import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/settings_provider.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import 'sales_detail_screen.dart';

class _CartItem {
  _CartItem(this.sp, this.qty);
  final Sparepart sp;
  int qty;
}

/// Kasir penjualan sparepart retail.
class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({super.key, this.customer});
  final Customer? customer;

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  bool _registered = false;
  Customer? _customer;
  final _walkIn = TextEditingController();
  final _paid = TextEditingController();
  final List<_CartItem> _cart = [];
  Discount? _discount;
  bool _busy = false;

  List<Sparepart> _stock = [];
  List<Discount> _discounts = [];
  List<Customer>? _customers;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _registered = true;
      _customer = widget.customer;
    }
    _loadRefs();
  }

  @override
  void dispose() {
    _walkIn.dispose();
    _paid.dispose();
    super.dispose();
  }

  Future<void> _loadRefs() async {
    try {
      final r = await Future.wait<dynamic>([
        Api.I.list('/spareparts', Sparepart.fromJson),
        Api.I.list('/discounts', Discount.fromJson, query: {'activeOnly': 'true'}),
      ]);
      if (!mounted) return;
      setState(() {
        _stock = r[0] as List<Sparepart>;
        _discounts = (r[1] as List<Discount>).where((d) => d.scope == 'SEMUA' || d.scope == 'SPAREPART').toList();
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  num get _taxRate => context.read<SettingsProvider>().taxSales;

  ({num subtotal, num disc, num tax, num total}) _calc() {
    final subtotal = _cart.fold<num>(0, (a, c) => a + c.sp.sellPrice * c.qty);
    num disc = _discount?.amountFor(subtotal) ?? 0;
    num after = subtotal - disc;
    if (after < 0) after = 0;
    final tax = after * _taxRate / 100;
    return (subtotal: subtotal, disc: disc, tax: tax, total: after + tax);
  }

  Future<void> _addItem() async {
    if (_stock.isEmpty) {
      toast(context, _error ?? 'Data sparepart belum tersedia.', error: true);
      return;
    }
    final sp = await showPickerSheet<Sparepart>(
      context,
      title: 'Pilih Sparepart',
      searchHint: 'Cari nama / kode...',
      scannable: true,
      items: _stock,
      matches: (e, q) => e.name.toLowerCase().contains(q) || e.code.toLowerCase().contains(q),
      exactMatch: (e, code) => e.code.toLowerCase() == code.toLowerCase(),
      disabled: (e) => e.stock <= 0,
      itemBuilder: (context, e) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${e.code} · stok ${e.stock}', style: TextStyle(color: e.stock <= 0 ? C.danger : C.mutedOf(context), fontSize: 12)),
              ],
            ),
          ),
          Text(rp(e.sellPrice), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (sp == null) return;
    final existing = _cart.where((c) => c.sp.id == sp.id).toList();
    if (existing.isNotEmpty) {
      _qty(existing.first, 1);
    } else {
      setState(() => _cart.add(_CartItem(sp, 1)));
    }
  }

  void _qty(_CartItem c, int delta) {
    final next = c.qty + delta;
    if (next < 1) return;
    if (next > c.sp.stock) {
      toast(context, 'Stok ${c.sp.name} hanya ${c.sp.stock}.', error: true);
      return;
    }
    setState(() => c.qty = next);
  }

  Future<void> _pickCustomer() async {
    try {
      _customers ??= await Api.I.list('/customers', Customer.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final c = await showPickerSheet<Customer>(
      context,
      title: 'Pilih Pelanggan',
      searchHint: 'Cari nama / No. HP...',
      items: _customers!,
      matches: (c, q) => c.name.toLowerCase().contains(q) || c.phone.contains(q),
      itemBuilder: (context, c) => Row(
        children: [
          Avatar(c.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(c.phone, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
    if (c != null) setState(() => _customer = c);
  }

  Future<void> _pickDiscount() async {
    final none = Discount(id: -1, name: 'Tanpa diskon', type: 'NOMINAL', value: 0, scope: 'SEMUA', status: 'AKTIF');
    final res = await showPickerSheet<Discount>(
      context,
      title: 'Pilih Diskon / Kupon',
      items: _discounts,
      matches: (d, q) => d.name.toLowerCase().contains(q) || (d.code?.toLowerCase().contains(q) ?? false),
      header: Builder(
        builder: (context) => ListTile(
          leading: Icon(Icons.block_rounded, color: C.mutedOf(context)),
          title: const Text('Tanpa diskon', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => Navigator.pop(context, none),
        ),
      ),
      itemBuilder: (context, d) => Row(
        children: [
          const IconTile(Icons.local_offer_rounded, color: C.ok, bg: C.okBg, size: 38),
          const SizedBox(width: 12),
          Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(d.type == 'PERCENTAGE' ? d.valueLabel : rp(d.value), style: const TextStyle(color: C.ok, fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (res != null) setState(() => _discount = res.id == -1 ? null : res);
  }

  Future<void> _save() async {
    final calc = _calc();
    final paid = parseRp(_paid.text);
    if (_cart.isEmpty) {
      toast(context, 'Tambahkan minimal 1 sparepart.', error: true);
      return;
    }
    if (_registered && _customer == null) {
      toast(context, 'Pilih pelanggan terdaftar atau gunakan Pelanggan Umum.', error: true);
      return;
    }
    if (paid <= 0 || paid < calc.total) {
      toast(context, 'Jumlah dibayar tidak boleh kurang dari ${rp(calc.total)}.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final d = await Api.I.post('/sales', body: {
        'customerId': _registered ? _customer!.id : null,
        'walkInName': _registered ? null : (_walkIn.text.trim().isEmpty ? 'Pelanggan Umum' : _walkIn.text.trim()),
        'items': _cart.map((c) => {'sparepartId': c.sp.id, 'qty': c.qty}).toList(),
        'discountId': _discount?.id,
        'paid': paid,
      });
      Bus.bump();
      final sale = Sale.fromJson(Map<String, dynamic>.from(d as Map));
      if (!mounted) return;
      toast(context, 'Penjualan ${sale.invoiceNo} tersimpan ✅');
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (context) => SalesDetailScreen(id: sale.id)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calc();
    final paid = parseRp(_paid.text);
    final change = paid > calc.total ? paid - calc.total : 0;
    final pas = calc.total.ceil();
    final quick = <int>{pas, (pas / 50000).ceil() * 50000, (pas / 100000).ceil() * 100000}.where((n) => n > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Penjualan Baru')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('Pelanggan Umum'), icon: Icon(Icons.person_outline_rounded)),
                    ButtonSegment(value: true, label: Text('Terdaftar'), icon: Icon(Icons.how_to_reg_rounded)),
                  ],
                  selected: {_registered},
                  onSelectionChanged: (s) => setState(() => _registered = s.first),
                ),
                const SizedBox(height: 14),
                if (_registered)
                  FieldTile(label: 'Pilih pelanggan', icon: Icons.person_rounded, value: _customer == null ? null : '${_customer!.name} · ${_customer!.phone}', onTap: _pickCustomer)
                else
                  LabeledField('Nama (opsional)', TextField(controller: _walkIn, textCapitalization: TextCapitalization.words, decoration: deco(null, icon: Icons.person_outline_rounded, hint: 'Pelanggan Umum'))),
              ],
            ),
          ),
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Item Sparepart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                if (_cart.isEmpty)
                  Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Keranjang masih kosong.', style: TextStyle(color: C.mutedOf(context)))),
                for (final c in _cart)
                  Container(
                    key: ObjectKey(c),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    decoration: BoxDecoration(color: C.bgOf(context), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.sp.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                              Text('${rp(c.sp.sellPrice)} · stok ${c.sp.stock}', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                              Text(rp(c.sp.sellPrice * c.qty), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => _qty(c, -1), icon: const Icon(Icons.remove_circle_outline_rounded)),
                        Text('${c.qty}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => _qty(c, 1), icon: Icon(Icons.add_circle_outline_rounded, color: C.brandOf(context))),
                        IconButton(visualDensity: VisualDensity.compact, onPressed: () => setState(() => _cart.remove(c)), icon: const Icon(Icons.delete_outline_rounded, color: C.danger)),
                      ],
                    ),
                  ),
                ActionButton(label: 'Tambah Sparepart (cari / scan)', icon: Icons.qr_code_scanner_rounded, kind: BtnKind.tonal, onPressed: _addItem),
              ],
            ),
          ),
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: FieldTile(
              label: 'Diskon / Kupon',
              icon: Icons.local_offer_rounded,
              value: _discount?.name ?? 'Tanpa diskon',
              onTap: _discounts.isEmpty ? null : _pickDiscount,
            ),
          ),
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                SummaryRow('Subtotal', rp(calc.subtotal)),
                SummaryRow('Diskon', '-${rp(calc.disc)}', color: C.ok),
                SummaryRow('Pajak (${_taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1)}%)', rp(calc.tax)),
                const Divider(height: 18),
                SummaryRow('Total', rp(calc.total), bold: true, big: true, color: C.brandOf(context)),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledField('Jumlah dibayar', TextField(
                  controller: _paid,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  onChanged: (_) => setState(() {}),
                  decoration: deco(null, hint: 'Contoh: 150000', icon: Icons.attach_money_rounded, prefixText: 'Rp '),
                )),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final n in quick)
                      ActionChip(
                        label: Text(n == pas ? 'Uang pas ${rp(n)}' : rp(n), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        backgroundColor: C.soft(context, C.brand50),
                        side: BorderSide.none,
                        onPressed: () => setState(() => _paid.text = num0(n)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: change > 0 ? C.soft(context, C.okBg) : C.bgOf(context), borderRadius: BorderRadius.circular(14)),
                  child: SummaryRow('Kembalian', rp(change), bold: true, color: change > 0 ? C.ok : C.mutedOf(context)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: C.cardOf(context),
          border: Border(top: BorderSide(color: C.lineOf(context))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                      Text(rp(calc.total), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: C.brandOf(context))),
                    ],
                  ),
                ),
                Expanded(child: ActionButton(label: 'Simpan', icon: Icons.check_rounded, kind: BtnKind.success, busy: _busy, onPressed: _save)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
