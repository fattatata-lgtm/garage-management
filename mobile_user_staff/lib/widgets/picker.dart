import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';
import 'scanner_page.dart';

/// Bottom sheet pilihan dengan pencarian (opsional tombol scan barcode).
/// Mengembalikan item terpilih, atau null bila ditutup.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required Widget Function(BuildContext context, T item) itemBuilder,
  required bool Function(T item, String query) matches,
  String searchHint = 'Cari...',
  bool scannable = false,
  bool Function(T item, String code)? exactMatch,
  Widget? header,
  bool Function(T item)? disabled,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PickerSheet<T>(
      title: title,
      items: items,
      itemBuilder: itemBuilder,
      matches: matches,
      searchHint: searchHint,
      scannable: scannable,
      exactMatch: exactMatch,
      header: header,
      disabled: disabled,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.matches,
    required this.searchHint,
    required this.scannable,
    this.exactMatch,
    this.header,
    this.disabled,
  });

  final String title;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool Function(T, String) matches;
  final String searchHint;
  final bool scannable;
  final bool Function(T, String)? exactMatch;
  final Widget? header;
  final bool Function(T)? disabled;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final TextEditingController _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<T> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((e) => widget.matches(e, q)).toList();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const ScannerPage()));
    if (code == null || !mounted) return;
    if (widget.exactMatch != null) {
      final hits = widget.items.where((e) => widget.exactMatch!(e, code)).toList();
      if (hits.length == 1 && !(widget.disabled?.call(hits.first) ?? false)) {
        Navigator.of(context).pop(hits.first);
        return;
      }
    }
    setState(() {
      _ctrl.text = code;
      _q = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(color: C.lineOf(context), borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SearchField(
                hint: widget.searchHint,
                controller: _ctrl,
                onChanged: (v) => setState(() => _q = v),
                trailing: widget.scannable
                    ? Material(
                        color: C.brand,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _scan,
                          child: const SizedBox(width: 50, height: 50, child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white)),
                        ),
                      )
                    : null,
              ),
            ),
            if (widget.header != null) widget.header!,
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('Tidak ada hasil', style: TextStyle(color: C.mutedOf(context))))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
                      itemBuilder: (context, i) {
                        final item = list[i];
                        final off = widget.disabled?.call(item) ?? false;
                        return Opacity(
                          opacity: off ? 0.45 : 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: off ? null : () => Navigator.pop(context, item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              child: widget.itemBuilder(context, item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilih supplier (dipakai form sparepart, filter daftar sparepart, dan Stok Masuk).
/// Mengembalikan null bila ditutup. [Supplier.id] == -1 berarti "tanpa supplier" / "semua supplier"
/// (sesuai [noneLabel]), sama seperti pola pilihan Kategori.
Future<Supplier?> pickSupplier(
  BuildContext context,
  List<Supplier> items, {
  String title = 'Pilih Supplier',
  String noneLabel = 'Tanpa Supplier',
}) {
  final none = Supplier(id: -1, name: noneLabel);
  return showPickerSheet<Supplier>(
    context,
    title: title,
    searchHint: 'Cari nama / kontak supplier...',
    items: items,
    matches: (s, q) => s.name.toLowerCase().contains(q) || (s.contactPerson?.toLowerCase().contains(q) ?? false),
    header: Builder(
      builder: (context) => ListTile(
        leading: Icon(Icons.local_shipping_rounded, color: C.brandOf(context)),
        title: Text(noneLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: () => Navigator.pop(context, none),
      ),
    ),
    itemBuilder: (context, s) {
      final sub = [s.contactPerson, s.phone].whereType<String>().join(' · ');
      return Row(children: [
        const IconTile(Icons.local_shipping_rounded, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (sub.isNotEmpty) Text(sub, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
          ]),
        ),
      ]);
    },
  );
}
