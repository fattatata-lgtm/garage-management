import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import 'service_detail_screen.dart';
import 'service_form_screen.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({super.key});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  static const _filters = <(String, String)>[
    ('ALL', 'Semua Status'),
    ('DITERIMA', 'Diterima'),
    ('DIKERJAKAN', 'Dikerjakan'),
    ('MENUNGGU_PEMBAYARAN', 'Menunggu Pembayaran'),
    ('SELESAI', 'Selesai (Lunas)'),
  ];

  String _q = '';
  DateTime? _from;
  DateTime? _to;
  String _filter = AppNav.serviceFilter.value;

  @override
  void initState() {
    super.initState();
    AppNav.serviceFilter.addListener(_onExternalFilter);
  }

  @override
  void dispose() {
    AppNav.serviceFilter.removeListener(_onExternalFilter);
    super.dispose();
  }

  void _onExternalFilter() {
    if (mounted) setState(() => _filter = AppNav.serviceFilter.value);
  }

  Future<List<Service>> _load() => Api.I.list('/services', Service.fromJson);

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasActive = _filter != 'ALL' || _from != null || _to != null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Filter Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (hasActive)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filter = 'ALL';
                              AppNav.serviceFilter.value = 'ALL';
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
                  const SizedBox(height: 14),
                  Text('Status Layanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
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
                            AppNav.serviceFilter.value = f.$1;
                          });
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
                  const SizedBox(height: 18),
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
                  if (_from != null || _to != null) ...[
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

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Layanan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const ServiceFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Service Baru'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hint: 'Cari no. invoice / plat...',
              onChanged: (v) => setState(() => _q = v),
              trailing: FilterIconButton(
                isActive: _filter != 'ALL' || _from != null || _to != null,
                tooltip: 'Filter Layanan',
                onTap: _openFilterSheet,
              ),
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (_filter != 'ALL')
                ('Status: ${_filters.firstWhere((e) => e.$1 == _filter, orElse: () => (_filter, _filter)).$2}', () {
                  setState(() => _filter = 'ALL');
                  AppNav.serviceFilter.value = 'ALL';
                }),
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
                _filter = 'ALL';
                AppNav.serviceFilter.value = 'ALL';
                _from = null;
                _to = null;
              });
            },
          ),
          Expanded(
            child: AsyncBody<List<Service>>(
              refreshOn: Bus.tick,
              loader: _load,
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((s) {
                  if (_filter != 'ALL' && s.status != _filter) return false;
                  if (!inDateRange(s.date, _from, _to)) return false;
                  if (q.isEmpty) return true;
                  return s.invoiceNo.toLowerCase().contains(q) ||
                      s.plate.toLowerCase().contains(q) ||
                      s.ownerName.toLowerCase().contains(q) ||
                      (s.technician?.name.toLowerCase().contains(q) ?? false);
                }).toList();
                if (list.isEmpty) {
                  return emptyList(Icons.build_circle_outlined, 'Tidak ada service', 'Ubah filter atau tekan "Service Baru".');
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ServiceTile(service: list[i], onTap: () => _open(ServiceDetailScreen(id: list[i].id))),
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: C.bgOf(context),
    );
  }
}
