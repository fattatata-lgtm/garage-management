import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import '../../widgets/scanner_page.dart';
import '../../widgets/tiles.dart';
import 'sparepart_detail_screen.dart';
import 'sparepart_form_screen.dart';

/// Pindai barcode lalu buka detail sparepart yang cocok (dipakai Dashboard & tab Sparepart).
Future<void> scanAndOpenSparepart(BuildContext context) async {
  final code = await go<String>(context, const ScannerPage());
  if (code == null || !context.mounted) return;
  try {
    final list = await Api.I.list('/spareparts', Sparepart.fromJson, query: {'q': code});
    if (!context.mounted) return;
    final exact = list.where((e) => e.code.toLowerCase() == code.toLowerCase()).toList();
    final hit = exact.isNotEmpty ? exact.first : (list.length == 1 ? list.first : null);
    if (hit == null) {
      toast(context, list.isEmpty ? 'Sparepart dengan kode "$code" tidak ditemukan.' : 'Ada ${list.length} hasil untuk "$code". Cari manual di tab Sparepart.', error: list.isEmpty);
      return;
    }
    await go<dynamic>(context, SparepartDetailScreen(id: hit.id));
    Bus.bump();
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
  }
}

class SparepartListScreen extends StatefulWidget {
  const SparepartListScreen({super.key});

  @override
  State<SparepartListScreen> createState() => _SparepartListScreenState();
}

class _SparepartListScreenState extends State<SparepartListScreen> {
  // Label sama dengan website: Semua Stok / Stok Menipis / Stok Habis / Stok Aman
  // ('ALERT' = Menipis + Habis, dipakai tautan dari Dashboard).
  static const _filters = <(String, String)>[
    ('ALL', 'Semua Stok'),
    ('ALERT', 'Perlu Perhatian'),
    ('RENDAH', 'Stok Menipis'),
    ('HABIS', 'Stok Habis'),
    ('BAIK', 'Stok Aman'),
  ];

  final _search = TextEditingController();
  String _q = '';
  String _filter = AppNav.stockFilter.value;
  Category? _category;
  List<Category>? _cats;
  Supplier? _supplier;
  List<Supplier>? _sups;
  final _key = GlobalKey<AsyncBodyState<List<Sparepart>>>();

  @override
  void initState() {
    super.initState();
    AppNav.stockFilter.addListener(_onExternal);
  }

  @override
  void dispose() {
    AppNav.stockFilter.removeListener(_onExternal);
    _search.dispose();
    super.dispose();
  }

  void _onExternal() {
    if (!mounted) return;
    setState(() => _filter = AppNav.stockFilter.value);
    _key.currentState?.reload();
  }

  /// Sama dengan website: categoryId, supplierId & stockStatus dikirim sebagai parameter ke server.
  Future<List<Sparepart>> _load() {
    final q = <String, dynamic>{};
    if (_category != null) q['categoryId'] = _category!.id;
    if (_supplier != null) q['supplierId'] = _supplier!.id;
    if (_filter == 'RENDAH' || _filter == 'HABIS' || _filter == 'BAIK') q['stockStatus'] = _filter;
    return Api.I.list('/spareparts', Sparepart.fromJson, query: q.isEmpty ? null : q);
  }

  Future<void> _pickCategory() async {
    try {
      _cats ??= await Api.I.list('/categories', Category.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final all = Category(id: -1, name: 'Semua Kategori');
    final c = await showPickerSheet<Category>(
      context,
      title: 'Filter Kategori',
      items: _cats!,
      matches: (c, q) => c.name.toLowerCase().contains(q),
      header: Builder(
        builder: (context) => ListTile(
          leading: Icon(Icons.category_rounded, color: C.brandOf(context)),
          title: const Text('Semua Kategori', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => Navigator.pop(context, all),
        ),
      ),
      itemBuilder: (context, c) => Row(children: [
        Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700))),
        Text('${c.count} item', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
      ]),
    );
    if (c == null) return;
    setState(() => _category = c.id == -1 ? null : c);
    _key.currentState?.reload();
  }

  Future<void> _pickSupplier() async {
    try {
      _sups ??= await Api.I.list('/suppliers', Supplier.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final r = await pickSupplier(context, _sups!, title: 'Filter Supplier', noneLabel: 'Semua Supplier');
    if (r == null) return;
    setState(() => _supplier = r.id == -1 ? null : r);
    _key.currentState?.reload();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Filter Sparepart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_category != null || _supplier != null || _filter != 'ALL')
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _category = null;
                              _supplier = null;
                              _filter = 'ALL';
                              AppNav.stockFilter.value = 'ALL';
                            });
                            _key.currentState?.reload();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset', style: TextStyle(color: C.danger, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Kategori', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickCategory();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: C.cardOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _category != null ? C.brandOf(context) : C.lineOf(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.layers_rounded, color: _category != null ? C.brandOf(context) : C.mutedOf(context), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _category?.name ?? 'Semua Kategori',
                              style: TextStyle(fontWeight: FontWeight.w700, color: _category != null ? C.brandOf(context) : C.textOf(context)),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: C.mutedOf(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickSupplier();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: C.cardOf(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _supplier != null ? C.brandOf(context) : C.lineOf(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping_rounded, color: _supplier != null ? C.brandOf(context) : C.mutedOf(context), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _supplier?.name ?? 'Semua Supplier',
                              style: TextStyle(fontWeight: FontWeight.w700, color: _supplier != null ? C.brandOf(context) : C.textOf(context)),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: C.mutedOf(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Status Stok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _filters.map((f) {
                      final sel = _filter == f.$1;
                      return ChoiceChip(
                        label: Text(f.$2),
                        selected: sel,
                        onSelected: (s) {
                          setModalState(() => _filter = f.$1);
                          setState(() {
                            _filter = f.$1;
                            AppNav.stockFilter.value = f.$1;
                          });
                          _key.currentState?.reload();
                        },
                        selectedColor: C.soft(context, C.brand50),
                        labelStyle: TextStyle(
                          color: sel ? C.brandOf(context) : C.textOf(context),
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                        ),
                        side: BorderSide(color: sel ? C.brandOf(context) : C.lineOf(context)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ActionButton(
                    label: 'Selesai',
                    kind: BtnKind.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sparepart')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const SparepartFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sparepart'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hint: 'Cari kode / nama sparepart...',
              controller: _search,
              onChanged: (v) => setState(() => _q = v),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: C.brand,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => scanAndOpenSparepart(context),
                      child: const SizedBox(width: 50, height: 50, child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterIconButton(
                    isActive: _category != null || _supplier != null || _filter != 'ALL',
                    tooltip: 'Filter Sparepart',
                    onTap: _openFilterSheet,
                  ),
                ],
              ),
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (_category != null)
                ('Kategori: ${_category!.name}', () {
                  setState(() => _category = null);
                  _key.currentState?.reload();
                }),
              if (_supplier != null)
                ('Supplier: ${_supplier!.name}', () {
                  setState(() => _supplier = null);
                  _key.currentState?.reload();
                }),
              if (_filter != 'ALL')
                ('Status: ${_filters.firstWhere((e) => e.$1 == _filter, orElse: () => (_filter, _filter)).$2}', () {
                  setState(() => _filter = 'ALL');
                  AppNav.stockFilter.value = 'ALL';
                  _key.currentState?.reload();
                }),
            ],
            onClearAll: () {
              setState(() {
                _category = null;
                _supplier = null;
                _filter = 'ALL';
                AppNav.stockFilter.value = 'ALL';
              });
              _key.currentState?.reload();
            },
          ),
          Expanded(
            child: AsyncBody<List<Sparepart>>(
              key: _key,
              refreshOn: Bus.tick,
              loader: _load,
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((e) {
                  final okStatus = switch (_filter) {
                    'ALL' => true,
                    'ALERT' => e.status != 'BAIK',
                    _ => e.status == _filter,
                  };
                  if (!okStatus) return false;
                  return q.isEmpty || e.name.toLowerCase().contains(q) || e.code.toLowerCase().contains(q) || e.categoryName.toLowerCase().contains(q);
                }).toList();
                if (list.isEmpty) return emptyList(Icons.inventory_2_outlined, 'Sparepart tidak ditemukan', 'Ubah kata kunci atau filter.');
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => SparepartTile(sparepart: list[i], onTap: () => _open(SparepartDetailScreen(id: list[i].id))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
