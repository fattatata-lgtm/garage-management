import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import '../../widgets/scanner_page.dart';

class SparepartFormScreen extends StatefulWidget {
  const SparepartFormScreen({super.key, this.sparepart});
  final Sparepart? sparepart;

  @override
  State<SparepartFormScreen> createState() => _SparepartFormScreenState();
}

class _SparepartFormScreenState extends State<SparepartFormScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _buy = TextEditingController();
  final _sell = TextEditingController();
  final _stock = TextEditingController();
  final _low = TextEditingController(text: '5');
  Category? _category;
  List<Category>? _categories;
  Supplier? _supplier; // opsional ("Tanpa Supplier")
  List<Supplier>? _suppliers;
  bool _busy = false;
  bool _submitted = false;

  bool get _edit => widget.sparepart != null;

  @override
  void initState() {
    super.initState();
    final s = widget.sparepart;
    if (s != null) {
      _code.text = s.code;
      _name.text = s.name;
      _buy.text = rpText(s.buyPrice);
      _sell.text = rpText(s.sellPrice);
      _low.text = '${s.lowStockThreshold}';
      _category = s.category ?? Category(id: s.categoryId, name: '-');
      _supplier = s.supplier ?? (s.supplierId != null ? Supplier(id: s.supplierId!, name: '-') : null);
    }
    _loadCategories();
    _loadSuppliers();
  }

  @override
  void dispose() {
    for (final c in [_code, _name, _buy, _sell, _stock, _low]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await Api.I.list('/categories', Category.fromJson);
      if (!mounted) return;
      setState(() {
        _categories = list;
        if (_category != null) {
          final match = list.where((c) => c.id == _category!.id).toList();
          if (match.isNotEmpty) _category = match.first;
        }
      });
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final list = await Api.I.list('/suppliers', Supplier.fromJson);
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        if (_supplier != null) {
          final match = list.where((x) => x.id == _supplier!.id).toList();
          if (match.isNotEmpty) _supplier = match.first;
        }
      });
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _pickSupplier() async {
    if (_suppliers == null) {
      await _loadSuppliers();
      if (_suppliers == null) return;
    }
    if (!mounted) return;
    final r = await pickSupplier(context, _suppliers!);
    if (r == null) return;
    setState(() => _supplier = r.id == -1 ? null : r);
  }

  Future<void> _pickCategory() async {
    if (_categories == null) {
      await _loadCategories();
      if (_categories == null) return;
    }
    if (!mounted) return;
    final c = await showPickerSheet<Category>(
      context,
      title: 'Pilih Kategori',
      items: _categories!,
      matches: (c, q) => c.name.toLowerCase().contains(q),
      itemBuilder: (context, c) => Row(children: [
        Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700))),
        Text('${c.count} item', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
      ]),
    );
    if (c != null) setState(() => _category = c);
  }

  Future<void> _scan() async {
    final code = await go<String>(context, const ScannerPage());
    if (code != null) setState(() => _code.text = code);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate() || _category == null) return;
    setState(() => _busy = true);
    final body = <String, dynamic>{
      'code': _code.text.trim(),
      'name': _name.text.trim(),
      'categoryId': _category!.id,
      // null = tanpa supplier (melepas supplier bila sebelumnya terisi)
      'supplierId': _supplier?.id,
      'buyPrice': parseRp(_buy.text),
      'sellPrice': parseRp(_sell.text),
      'lowStockThreshold': int.tryParse(_low.text.trim()) ?? 5,
    };
    try {
      if (_edit) {
        await Api.I.put('/spareparts/${widget.sparepart!.id}', body: body);
      } else {
        body['stock'] = parseRp(_stock.text);
        await Api.I.post('/spareparts', body: body);
      }
      Bus.bump();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message, error: true);
      }
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Sparepart' : 'Sparepart Baru')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LabeledField('Kode / Barcode', TextFormField(
              controller: _code,
              validator: _req,
              textCapitalization: TextCapitalization.characters,
              decoration: deco(null, hint: 'Ketik atau scan, mis. OLI-001', icon: Icons.qr_code_2_rounded, suffix: IconButton(onPressed: _scan, icon: const Icon(Icons.qr_code_scanner_rounded))),
            )),
            const SizedBox(height: 14),
            LabeledField('Nama sparepart', TextFormField(controller: _name, validator: _req, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Contoh: Oli Mesin 1 Liter', icon: Icons.settings_rounded))),
            const SizedBox(height: 14),
            FieldTile(
              label: 'Kategori',
              icon: Icons.category_rounded,
              value: _category?.name == '-' ? null : _category?.name,
              error: _submitted && _category == null ? 'Pilih kategori' : null,
              onTap: _pickCategory,
            ),
            const SizedBox(height: 14),
            FieldTile(
              label: 'Supplier (opsional)',
              icon: Icons.local_shipping_rounded,
              value: _supplier == null ? 'Tanpa Supplier' : (_supplier!.name == '-' ? null : _supplier!.name),
              trailing: _supplier != null
                  ? GestureDetector(
                      onTap: () => setState(() => _supplier = null),
                      child: const Icon(Icons.close_rounded, size: 20),
                    )
                  : const Icon(Icons.keyboard_arrow_down_rounded),
              onTap: _pickSupplier,
            ),
            const SizedBox(height: 14),
            LabeledField('Harga beli', TextFormField(
              controller: _buy,
              validator: _req,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: deco(null, hint: 'Contoh: 45000', icon: Icons.south_west_rounded, prefixText: 'Rp '),
            )),
            const SizedBox(height: 14),
            LabeledField('Harga jual', TextFormField(
              controller: _sell,
              validator: _req,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: deco(null, hint: 'Contoh: 60000', icon: Icons.north_east_rounded, prefixText: 'Rp '),
            )),
            const SizedBox(height: 14),
            if (!_edit) ...[
              LabeledField('Stok awal', TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsFormatter()],
                decoration: deco(null, hint: 'Contoh: 20', icon: Icons.inventory_2_rounded),
              )),
              const SizedBox(height: 14),
            ],
            LabeledField('Batas stok rendah', TextFormField(
              controller: _low,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco(null, hint: 'Contoh: 5', icon: Icons.warning_amber_rounded),
            )),
            const SizedBox(height: 24),
            ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
