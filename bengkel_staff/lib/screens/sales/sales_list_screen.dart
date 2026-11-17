import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import 'sales_detail_screen.dart';
import 'sales_form_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  String _q = '';
  DateTime? _from;
  DateTime? _to;

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasActive = _from != null || _to != null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Filter Penjualan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (hasActive)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _from = null;
                              _to = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset', style: TextStyle(color: C.danger, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FieldTile(
                          label: 'Tgl Mulai',
                          dense: true,
                          hint: 'Pilih',
                          icon: Icons.calendar_month_rounded,
                          value: _from == null ? null : fmtDate(_from),
                          trailing: const SizedBox.shrink(),
                          onTap: () async {
                            final d = await pickDate(context, initial: _from ?? _to, last: _to);
                            if (d != null) {
                              setModalState(() => _from = d);
                              setState(() => _from = d);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FieldTile(
                          label: 'Tgl Akhir',
                          dense: true,
                          hint: 'Pilih',
                          icon: Icons.calendar_month_rounded,
                          value: _to == null ? null : fmtDate(_to),
                          trailing: const SizedBox.shrink(),
                          onTap: () async {
                            final d = await pickDate(context, initial: _to ?? _from, first: _from);
                            if (d != null) {
                              setModalState(() => _to = d);
                              setState(() => _to = d);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (hasActive) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            _from = null;
                            _to = null;
                          });
                          setState(() {
                            _from = null;
                            _to = null;
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Hapus filter tanggal'),
                      ),
                    ),
                  ],
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
      appBar: AppBar(title: const Text('Penjualan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const SalesFormScreen()),
        icon: const Icon(Icons.add_shopping_cart_rounded),
        label: const Text('Penjualan Baru'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hint: 'Cari no. invoice...',
              onChanged: (v) => setState(() => _q = v),
              trailing: FilterIconButton(
                isActive: _from != null || _to != null,
                tooltip: 'Filter Tanggal',
                onTap: _openFilterSheet,
              ),
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (_from != null || _to != null)
                ('Tanggal: ${_from == null ? 'awal' : fmtDate(_from)} – ${_to == null ? 'sekarang' : fmtDate(_to)}', () {
                  setState(() {
                    _from = null;
                    _to = null;
                  });
                }),
            ],
            onClearAll: () {
              setState(() {
                _from = null;
                _to = null;
              });
            },
          ),
          Expanded(
            child: AsyncBody<List<Sale>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/sales', Sale.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((s) => inDateRange(s.date, _from, _to) && (q.isEmpty || s.invoiceNo.toLowerCase().contains(q) || s.customerName.toLowerCase().contains(q))).toList();
                if (list.isEmpty) {
                  return emptyList(Icons.receipt_long_outlined, 'Belum ada penjualan', 'Tekan "Penjualan Baru" untuk mencatat penjualan sparepart.');
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => SaleTile(sale: list[i], onTap: () => _open(SalesDetailScreen(id: list[i].id))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
