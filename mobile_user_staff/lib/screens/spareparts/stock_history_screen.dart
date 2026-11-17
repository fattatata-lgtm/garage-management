import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'sparepart_detail_screen.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  String _filter = 'ALL';
  String _q = '';

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          const options = [('ALL', 'Semua'), ('MASUK', 'Masuk'), ('KELUAR', 'Keluar')];
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Filter Riwayat Stok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_filter != 'ALL')
                        TextButton(
                          onPressed: () {
                            setState(() => _filter = 'ALL');
                            Navigator.pop(context);
                          },
                          child: const Text('Reset', style: TextStyle(color: C.danger, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Arah Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: options.map((f) {
                      final sel = _filter == f.$1;
                      return ChoiceChip(
                        label: Text(f.$2),
                        selected: sel,
                        onSelected: (s) {
                          setModalState(() => _filter = f.$1);
                          setState(() => _filter = f.$1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Stok')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hint: 'Cari sparepart / supplier / invoice...',
              onChanged: (v) => setState(() => _q = v),
              trailing: FilterIconButton(
                isActive: _filter != 'ALL',
                tooltip: 'Filter Riwayat',
                onTap: _openFilterSheet,
              ),
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (_filter != 'ALL')
                ('Arah: ${_filter == 'MASUK' ? 'Masuk' : 'Keluar'}', () {
                  setState(() => _filter = 'ALL');
                }),
            ],
            onClearAll: () => setState(() => _filter = 'ALL'),
          ),
          Expanded(
            child: AsyncBody<List<StockHistory>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/spareparts/history/all', StockHistory.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((h) {
                  if (_filter != 'ALL' && h.direction != _filter) return false;
                  return q.isEmpty ||
                      (h.sparepartName?.toLowerCase().contains(q) ?? false) ||
                      (h.supplierName?.toLowerCase().contains(q) ?? false) ||
                      (h.refInvoice?.toLowerCase().contains(q) ?? false);
                }).toList();
                if (list.isEmpty) return emptyList(Icons.history_rounded, 'Tidak ada riwayat');
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => AppCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.zero,
                    child: HistoryRow(item: list[i], showName: true),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}