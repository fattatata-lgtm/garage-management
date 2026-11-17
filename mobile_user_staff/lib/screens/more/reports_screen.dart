import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/settings_provider.dart';
import '../../print/pdf_docs.dart';
import '../../print/printer.dart';
import '../../widgets/picker.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import '../customers/customer_detail_screen.dart';
import '../sales/sales_detail_screen.dart';
import '../services/service_detail_screen.dart';
import '../../core/nav.dart';

/// Nomor tab laporan (urutan sama dengan menu Laporan di website).
const int kTabService = 0;
const int kTabSales = 1;
const int kTabSparepart = 2;
const int kTabLoyalty = 3;
const int kTabStock = 4;

const Map<String, String> _sourceLabel = {
  'ALL': 'Semua (Service + Penjualan)',
  'SERVICE': 'Service',
  'SALES': 'Penjualan',
};

class _Report {
  _Report(
    this.summary, {
    this.services = const [],
    this.sales = const [],
    this.parts = const [],
    this.topServices = const [],
    this.partSales = const [],
    this.loyalty = const [],
    this.activeDays = 90,
  });
  final Map<String, dynamic> summary;
  final List<Service> services;
  final List<Sale> sales;
  final List<Sparepart> parts;
  final List<TopService> topServices;
  final List<SparepartSales> partSales;
  final List<LoyaltyRow> loyalty;
  final int activeDays;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late int _tab = widget.initialTab;
  late DateTimeRange _range = _preset('month');
  String _preset0 = 'month';
  String _stockFilter = 'ALL';
  String _source = 'ALL'; // sumber data: Laporan Sparepart & Loyalitas (ALL | SERVICE | SALES)
  String _svcView = 'ALL'; // Laporan Layanan: ALL = semua transaksi, TOP = layanan paling laris
  Customer? _customer; // filter pelanggan (Layanan & Penjualan)
  Category? _category; // filter kategori (Stok)
  List<Customer>? _customers;
  List<Category>? _cats;
  _Report? _last;
  final _key = GlobalKey<AsyncBodyState<_Report>>();
  final _tabKeys = List.generate(5, (_) => GlobalKey());

  /// Laporan berdasarkan periode tanggal (semua kecuali Stok).
  bool get _dated => _tab != kTabStock;
  bool get _hasCustomerFilter => _tab == kTabService || _tab == kTabSales;
  bool get _hasSourceFilter => _tab == kTabSparepart || _tab == kTabLoyalty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTab());
  }

  /// Geser baris tab agar tab aktif terlihat (ada 5 laporan, lebih lebar dari layar HP).
  void _revealTab() {
    final c = _tabKeys[_tab].currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 250), alignment: 0.5, curve: Curves.easeOut);
  }

  /// Pindah laporan: filter direset (sama seperti website).
  void _selectTab(int i) {
    if (i == _tab) return;
    setState(() {
      _tab = i;
      _preset0 = 'month';
      _range = _preset('month');
      _customer = null;
      _category = null;
      _stockFilter = 'ALL';
      _source = 'ALL';
      _svcView = 'ALL';
    });
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTab());
  }

  static DateTimeRange _preset(String p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (p) {
      case 'day':
        return DateTimeRange(start: today, end: today);
      case 'week':
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      default:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: today);
    }
  }

  Future<_Report> _load() async {
    final q = <String, dynamic>{'from': startOfDayApi(_range.start), 'to': endOfDayApi(_range.end)};
    if (_customer != null && _hasCustomerFilter) q['customerId'] = _customer!.id;
    if (_hasSourceFilter) q['source'] = _source;
    List<T> rows<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
        (v as List).whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
    _Report rep;
    switch (_tab) {
      case kTabService:
        {
          final d = Map<String, dynamic>.from(await Api.I.get('/reports/service', query: q) as Map);
          rep = _Report(
            Map<String, dynamic>.from(d['summary'] as Map),
            services: rows(d['detail'], Service.fromJson),
            topServices: rows(d['topServices'] ?? const [], TopService.fromJson),
          );
        }
      case kTabSales:
        {
          final d = Map<String, dynamic>.from(await Api.I.get('/reports/sales', query: q) as Map);
          rep = _Report(Map<String, dynamic>.from(d['summary'] as Map), sales: rows(d['detail'], Sale.fromJson));
        }
      case kTabSparepart:
        {
          final d = Map<String, dynamic>.from(await Api.I.get('/reports/sparepart', query: q) as Map);
          rep = _Report(Map<String, dynamic>.from(d['summary'] as Map), partSales: rows(d['detail'], SparepartSales.fromJson));
        }
      case kTabLoyalty:
        {
          final d = Map<String, dynamic>.from(await Api.I.get('/reports/loyalty', query: q) as Map);
          rep = _Report(
            Map<String, dynamic>.from(d['summary'] as Map),
            loyalty: rows(d['detail'], LoyaltyRow.fromJson),
            activeDays: (num.tryParse('${d['activeDays']}') ?? 90).toInt(),
          );
        }
      default:
        {
          final d = Map<String, dynamic>.from(await Api.I.get('/reports/stock', query: _category == null ? null : {'categoryId': _category!.id}) as Map);
          rep = _Report(Map<String, dynamic>.from(d['summary'] as Map), parts: rows(d['detail'], Sparepart.fromJson));
        }
    }
    _last = rep;
    return rep;
  }

  Future<void> _pickCustomer() async {
    try {
      _customers ??= await Api.I.list('/customers', Customer.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final all = Customer(id: -1, name: 'Semua Pelanggan', phone: '');
    final c = await showPickerSheet<Customer>(
      context,
      title: 'Filter Pelanggan',
      searchHint: 'Cari nama / No. HP...',
      items: _customers!,
      matches: (c, q) => c.name.toLowerCase().contains(q) || c.phone.contains(q),
      header: Builder(
        builder: (context) => ListTile(
          leading: Icon(Icons.people_alt_rounded, color: C.brandOf(context)),
          title: const Text('Semua Pelanggan', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => Navigator.pop(context, all),
        ),
      ),
      itemBuilder: (context, c) => Row(children: [
        Avatar(c.name, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(c.phone, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
          ]),
        ),
      ]),
    );
    if (c == null) return;
    setState(() => _customer = c.id == -1 ? null : c);
    _reload();
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
    _reload();
  }

  /// Cetak / simpan PDF (sama dengan "Cetak / Simpan PDF" di web): memuat SEMUA baris.
  Future<void> _print() async {
    final r = _last;
    if (r == null) {
      toast(context, 'Data laporan belum dimuat.', error: true);
      return;
    }
    final st = context.read<SettingsProvider>();
    final shop = PrintService.shop(st);
    final filters = <String>[];
    if (_dated) filters.add('Periode: ${fmtDate(_range.start)} - ${fmtDate(_range.end)}');
    if (_hasCustomerFilter && _customer != null) filters.add('Pelanggan: ${_customer!.name}');
    if (_hasSourceFilter) filters.add('Sumber: ${_sourceLabel[_source]}');
    if (_tab == kTabService && _svcView == 'TOP') filters.add('Tampilan: Layanan Paling Laris');
    if (_tab == kTabStock && _category != null) filters.add('Kategori: ${_category!.name}');
    if (_tab == kTabStock && _stockFilter != 'ALL') filters.add('Status: ${statusLabel(_stockFilter)}');

    final showService = _source != 'SALES';
    final showSales = _source != 'SERVICE';
    late String title;
    late List<(String, String)> summary;
    late List<String> headers;
    late List<List<String>> rows;
    late List<double> flex;
    if (_tab == kTabService) {
      title = 'Laporan Layanan Service';
      summary = [
        ('Total Service', '${_s(r.summary, 'totalService').toInt()}'),
        ('Total Biaya', rp(_s(r.summary, 'totalBiaya'))),
        ('Selesai', '${_s(r.summary, 'selesai').toInt()}'),
        ('Berjalan', '${_s(r.summary, 'berjalan').toInt()}'),
      ];
      if (_svcView == 'TOP') {
        headers = ['No', 'Layanan', 'Dipakai (kali)', 'Total Biaya Jasa'];
        flex = [0.6, 4, 1.6, 2.2];
        rows = [
          for (var i = 0; i < r.topServices.length; i++) ['${i + 1}', r.topServices[i].name, '${r.topServices[i].count}', rp(r.topServices[i].revenue)],
        ];
      } else {
        headers = ['No', 'Invoice', 'Tanggal', 'Pelanggan', 'Kendaraan', 'Status', 'Total'];
        flex = [0.6, 2.3, 1.6, 2, 2.2, 1.5, 1.8];
        rows = [
          for (var i = 0; i < r.services.length; i++)
            ['${i + 1}', r.services[i].invoiceNo, fmtDate(r.services[i].date), r.services[i].ownerName, '${r.services[i].plate} ${r.services[i].vehicle?.modelLabel ?? ''}', statusLabel(r.services[i].status), rp(r.services[i].total)],
        ];
      }
    } else if (_tab == kTabSales) {
      title = 'Laporan Penjualan';
      summary = [
        ('Total Penjualan', rp(_s(r.summary, 'totalPenjualan'))),
        ('Total Laba', rp(_s(r.summary, 'totalLaba'))),
        ('Jumlah Transaksi', '${_s(r.summary, 'jumlahTransaksi').toInt()}'),
        ('Item Terjual', '${_s(r.summary, 'jumlahItem').toInt()}'),
      ];
      headers = ['No', 'Invoice', 'Tanggal', 'Pelanggan', 'Item', 'Total'];
      flex = [0.6, 2.3, 2, 2.2, 0.8, 1.8];
      rows = [
        for (var i = 0; i < r.sales.length; i++)
          ['${i + 1}', r.sales[i].invoiceNo, fmtDateTime(r.sales[i].date), r.sales[i].customerName, '${r.sales[i].itemCount}', rp(r.sales[i].total)],
      ];
    } else if (_tab == kTabSparepart) {
      title = 'Laporan Sparepart';
      summary = [
        ('Jenis Sparepart', '${_s(r.summary, 'jenisTerjual').toInt()}'),
        ('Total Qty Terjual', '${_s(r.summary, 'totalQty').toInt()}'),
        ('Total Nilai', rp(_s(r.summary, 'totalNilai'))),
        ('Sparepart Terlaris', '${r.summary['terlaris'] ?? '-'}'),
      ];
      headers = ['No', 'Kode', 'Nama', 'Kategori', if (showService) 'Service', if (showSales) 'Penjualan', 'Total Qty', 'Nilai', 'Laba'];
      flex = [0.6, 1.5, 3, 1.8, if (showService) 1, if (showSales) 1.2, 1.1, 1.8, 1.8];
      rows = [
        for (var i = 0; i < r.partSales.length; i++)
          [
            '${i + 1}',
            r.partSales[i].code,
            r.partSales[i].name,
            r.partSales[i].category,
            if (showService) '${r.partSales[i].qtyService}',
            if (showSales) '${r.partSales[i].qtySales}',
            '${r.partSales[i].qtyTotal}',
            rp(r.partSales[i].revenue),
            rp(r.partSales[i].profit),
          ],
      ];
    } else if (_tab == kTabLoyalty) {
      title = 'Laporan Loyalitas Pelanggan';
      summary = [
        ('Total Pelanggan', '${_s(r.summary, 'totalPelanggan').toInt()}'),
        ('Total Transaksi', '${_s(r.summary, 'totalTransaksi').toInt()}'),
        ('Rata-rata Transaksi', '${_s(r.summary, 'rataTransaksi')}'),
        ('Total Belanja', rp(_s(r.summary, 'totalBelanja'))),
      ];
      headers = ['No', 'Pelanggan', 'Telepon', if (showService) 'Service', if (showSales) 'Penjualan', 'Total Transaksi', 'Total Belanja', 'Terakhir', 'Status'];
      flex = [0.6, 2.6, 2, if (showService) 1, if (showSales) 1.2, 1.5, 2, 1.8, 1.4];
      rows = [
        for (var i = 0; i < r.loyalty.length; i++)
          [
            '${i + 1}',
            r.loyalty[i].name,
            r.loyalty[i].phone,
            if (showService) '${r.loyalty[i].serviceCount}',
            if (showSales) '${r.loyalty[i].salesCount}',
            '${r.loyalty[i].visits}',
            rp(r.loyalty[i].totalSpent),
            fmtDate(r.loyalty[i].lastDate),
            r.loyalty[i].active ? 'Aktif' : 'Nonaktif',
          ],
      ];
    } else {
      title = 'Laporan Stok';
      final list = r.parts.where((p) => _stockFilter == 'ALL' || p.status == _stockFilter).toList();
      summary = [
        ('Total Item', '${_s(r.summary, 'totalItems').toInt()}'),
        ('Nilai Stok', rp(_s(r.summary, 'totalStockValue'))),
        ('Stok Rendah', '${_s(r.summary, 'rendah').toInt()}'),
        ('Stok Habis', '${_s(r.summary, 'habis').toInt()}'),
      ];
      headers = ['No', 'Kode', 'Nama', 'Kategori', 'Stok', 'Harga Beli', 'Nilai Stok', 'Status'];
      flex = [0.6, 1.5, 3, 1.8, 0.8, 1.6, 1.8, 1.4];
      rows = [
        for (var i = 0; i < list.length; i++)
          ['${i + 1}', list[i].code, list[i].name, list[i].categoryName, '${list[i].stock}', rp(list[i].buyPrice), rp(list[i].buyPrice * list[i].stock), statusLabel(list[i].status)],
      ];
    }
    try {
      final bytes = await buildReportPdf(title: title, filters: filters, summary: summary, headers: headers, rows: rows, flex: flex, shop: shop);
      await showPdf(bytes, title);
    } catch (e) {
      if (mounted) toast(context, 'Gagal membuat PDF: $e', error: true);
    }
  }

  void _reload() => _key.currentState?.reload();

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _range,
    );
    if (r != null) {
      setState(() {
        _range = r;
        _preset0 = 'custom';
      });
      _reload();
    }
  }

  static const _stockOptions = <(String, String)>[('ALL', 'Semua'), ('HABIS', 'Habis'), ('RENDAH', 'Rendah'), ('BAIK', 'Baik')];
  static const _presetOptions = <(String, String)>[('day', 'Hari ini'), ('week', '7 hari'), ('month', 'Bulan ini')];
  static const _tabOptions = <(int, String)>[
    (kTabService, 'Layanan'),
    (kTabSales, 'Penjualan'),
    (kTabSparepart, 'Sparepart'),
    (kTabLoyalty, 'Loyalitas'),
    (kTabStock, 'Stok'),
  ];

  String _presetLabel(String p) => p == 'custom' ? 'Pilih tanggal' : _presetOptions.firstWhere((e) => e.$1 == p, orElse: () => (p, p)).$2;

  bool get _hasActiveFilter => _dated
      ? (_preset0 != 'month' ||
          (_hasCustomerFilter && _customer != null) ||
          (_hasSourceFilter && _source != 'ALL') ||
          (_tab == kTabService && _svcView != 'ALL'))
      : (_category != null || _stockFilter != 'ALL');

  void _resetFilters() {
    setState(() {
      _preset0 = 'month';
      _range = _preset('month');
      _customer = null;
      _category = null;
      _stockFilter = 'ALL';
      _source = 'ALL';
      _svcView = 'ALL';
    });
    _reload();
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (_) => onTap(),
                selectedColor: C.soft(context, C.brand50),
                labelStyle: TextStyle(color: sel ? C.brandOf(context) : C.textOf(context), fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
                side: BorderSide(color: sel ? C.brandOf(context) : C.lineOf(context)),
              );
          Widget label(String t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
              );
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Filter Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_hasActiveFilter)
                        TextButton(
                          onPressed: () {
                            _resetFilters();
                            Navigator.pop(context);
                          },
                          child: const Text('Reset', style: TextStyle(color: C.danger, fontWeight: FontWeight.w700)),
                        ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_dated) ...[
                    label('Periode'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in _presetOptions)
                          chip(o.$2, _preset0 == o.$1, () {
                            setState(() {
                              _preset0 = o.$1;
                              _range = _preset(o.$1);
                            });
                            setModalState(() {});
                            _reload();
                          }),
                        chip('Pilih tanggal', _preset0 == 'custom', () async {
                          await _pickRange();
                          setModalState(() {});
                        }),
                      ],
                    ),
                    if (_tab == kTabService) ...[
                      const SizedBox(height: 18),
                      label('Tampilan'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          chip('Semua Layanan', _svcView == 'ALL', () {
                            setState(() => _svcView = 'ALL');
                            setModalState(() {});
                          }),
                          chip('Layanan Paling Laris', _svcView == 'TOP', () {
                            setState(() => _svcView = 'TOP');
                            setModalState(() {});
                          }),
                        ],
                      ),
                    ],
                    if (_hasSourceFilter) ...[
                      const SizedBox(height: 18),
                      label('Sumber Data'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in _sourceLabel.entries)
                            chip(e.value, _source == e.key, () {
                              setState(() => _source = e.key);
                              setModalState(() {});
                              _reload();
                            }),
                        ],
                      ),
                    ],
                    if (_hasCustomerFilter) ...[
                      const SizedBox(height: 18),
                      FieldTile(
                        label: 'Pelanggan',
                        icon: Icons.people_alt_rounded,
                        value: _customer == null ? 'Semua Pelanggan' : '${_customer!.name}${_customer!.phone.isNotEmpty ? ' (${_customer!.phone})' : ''}',
                        trailing: _customer != null
                            ? GestureDetector(
                                onTap: () {
                                  setState(() => _customer = null);
                                  setModalState(() {});
                                  _reload();
                                },
                                child: const Icon(Icons.close_rounded, size: 20),
                              )
                            : const Icon(Icons.keyboard_arrow_down_rounded),
                        onTap: () async {
                          await _pickCustomer();
                          setModalState(() {});
                        },
                      ),
                    ],
                  ] else ...[
                    FieldTile(
                      label: 'Kategori',
                      icon: Icons.category_rounded,
                      value: _category?.name ?? 'Semua Kategori',
                      trailing: _category != null
                          ? GestureDetector(
                              onTap: () {
                                setState(() => _category = null);
                                setModalState(() {});
                                _reload();
                              },
                              child: const Icon(Icons.close_rounded, size: 20),
                            )
                          : const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: () async {
                        await _pickCategory();
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 18),
                    label('Status Stok'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in _stockOptions)
                          chip(o.$2, _stockFilter == o.$1, () {
                            setState(() => _stockFilter = o.$1);
                            setModalState(() {});
                          }),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  ActionButton(label: 'Selesai', kind: BtnKind.primary, onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color c, Color bg) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon, color: c, bg: bg, size: 36),
            const SizedBox(height: 10),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
            Text(label, style: TextStyle(color: C.mutedOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// Lencana nomor urut (3 teratas diberi warna emas).
  Widget _rank(int n) {
    final top = n <= 3;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: top ? C.soft(context, C.warnBg) : C.soft(context, C.brand50), shape: BoxShape.circle),
      child: Text('$n', style: TextStyle(color: top ? C.tone(context, C.warn) : C.brandOf(context), fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dated = _dated;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [IconButton(tooltip: 'Cetak / Simpan PDF', icon: const Icon(Icons.print_rounded), onPressed: _print)],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final t in _tabOptions)
                  Padding(
                    key: _tabKeys[t.$1],
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.$2),
                      selected: _tab == t.$1,
                      onSelected: (_) => _selectTab(t.$1),
                      showCheckmark: false,
                      selectedColor: C.fillOf(context),
                      backgroundColor: C.cardOf(context),
                      labelStyle: TextStyle(color: _tab == t.$1 ? Colors.white : C.textOf(context), fontWeight: FontWeight.w800, fontSize: 13.5),
                      side: BorderSide(color: _tab == t.$1 ? C.fillOf(context) : C.lineOf(context)),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: C.cardOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.lineOf(context)),
                    ),
                    child: Row(
                      children: [
                        Icon(dated ? Icons.date_range_rounded : Icons.inventory_2_rounded, size: 20, color: C.mutedOf(context)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dated ? '${fmtDate(_range.start)} – ${fmtDate(_range.end)}' : 'Kondisi stok saat ini',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: C.textOf(context), fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterIconButton(
                  isActive: _hasActiveFilter,
                  tooltip: 'Filter Laporan',
                  onTap: _openFilterSheet,
                ),
              ],
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (dated && _preset0 != 'month')
                ('Periode: ${_presetLabel(_preset0)}', () {
                  setState(() {
                    _preset0 = 'month';
                    _range = _preset('month');
                  });
                  _reload();
                }),
              if (_hasCustomerFilter && _customer != null)
                ('Pelanggan: ${_customer!.name}', () {
                  setState(() => _customer = null);
                  _reload();
                }),
              if (_hasSourceFilter && _source != 'ALL')
                ('Sumber: ${_sourceLabel[_source]}', () {
                  setState(() => _source = 'ALL');
                  _reload();
                }),
              if (_tab == kTabService && _svcView == 'TOP') ('Tampilan: Layanan Paling Laris', () => setState(() => _svcView = 'ALL')),
              if (!dated && _category != null)
                ('Kategori: ${_category!.name}', () {
                  setState(() => _category = null);
                  _reload();
                }),
              if (!dated && _stockFilter != 'ALL')
                ('Status: ${statusLabel(_stockFilter)}', () => setState(() => _stockFilter = 'ALL')),
            ],
            onClearAll: _resetFilters,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: AsyncBody<_Report>(
              key: _key,
              loader: _load,
              builder: (context, r, reload) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                children: switch (_tab) {
                  kTabService => _service(r),
                  kTabSales => _sales(r),
                  kTabSparepart => _sparepart(r),
                  kTabLoyalty => _loyalty(r),
                  _ => _stock(r),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  num _s(Map<String, dynamic> m, String k) => num.tryParse('${m[k]}') ?? 0;

  Widget _emptyCard([String text = 'Tidak ada data pada periode ini']) =>
      AppCard(child: Center(child: Text(text, style: TextStyle(color: C.mutedOf(context)))));

  List<Widget> _service(_Report r) => [
        Row(children: [
          _stat('Total service', '${_s(r.summary, 'totalService').toInt()}', Icons.build_rounded, C.brand, C.brand50),
          const SizedBox(width: 12),
          _stat('Total biaya', rp(_s(r.summary, 'totalBiaya')), Icons.payments_rounded, C.ok, C.okBg),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('Selesai', '${_s(r.summary, 'selesai').toInt()}', Icons.check_circle_rounded, C.ok, C.okBg),
          const SizedBox(width: 12),
          _stat('Berjalan', '${_s(r.summary, 'berjalan').toInt()}', Icons.hourglass_top_rounded, C.warn, C.warnBg),
        ]),
        if (_svcView == 'TOP') ...[
          const SectionTitle('Layanan Paling Laris'),
          if (r.topServices.isEmpty)
            _emptyCard()
          else
            for (var i = 0; i < r.topServices.length; i++)
              AppCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _rank(i + 1),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.topServices[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          Text('Dipakai ${r.topServices[i].count} kali', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rp(r.topServices[i].revenue), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: C.ok)),
                        Text('biaya jasa', style: TextStyle(color: C.mutedOf(context), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
        ] else ...[
          const SectionTitle('Detail Transaksi'),
          if (r.services.isEmpty)
            _emptyCard()
          else
            for (final s in r.services) ServiceTile(service: s, onTap: () => go<dynamic>(context, ServiceDetailScreen(id: s.id))),
        ],
      ];

  List<Widget> _sales(_Report r) => [
        Row(children: [
          _stat('Total penjualan', rp(_s(r.summary, 'totalPenjualan')), Icons.point_of_sale_rounded, C.ok, C.okBg),
          const SizedBox(width: 12),
          _stat('Total laba', rp(_s(r.summary, 'totalLaba')), Icons.trending_up_rounded, C.brand, C.brand50),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _stat('Transaksi', '${_s(r.summary, 'jumlahTransaksi').toInt()}', Icons.receipt_long_rounded, C.violet, C.violetBg),
          const SizedBox(width: 12),
          _stat('Item terjual', '${_s(r.summary, 'jumlahItem').toInt()}', Icons.shopping_bag_rounded, C.warn, C.warnBg),
        ]),
        const SectionTitle('Detail Transaksi'),
        if (r.sales.isEmpty)
          _emptyCard()
        else
          for (final s in r.sales) SaleTile(sale: s, onTap: () => go<dynamic>(context, SalesDetailScreen(id: s.id))),
      ];

  /// Laporan Sparepart: sparepart paling laris dari service + penjualan.
  List<Widget> _sparepart(_Report r) {
    final showService = _source != 'SALES';
    final showSales = _source != 'SERVICE';
    return [
      Row(children: [
        _stat('Jenis sparepart', '${_s(r.summary, 'jenisTerjual').toInt()}', Icons.settings_rounded, C.brand, C.brand50),
        const SizedBox(width: 12),
        _stat('Total qty terjual', '${_s(r.summary, 'totalQty').toInt()}', Icons.swap_horiz_rounded, const Color(0xFF0891B2), const Color(0xFFECFEFF)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _stat('Total nilai', rp(_s(r.summary, 'totalNilai')), Icons.payments_rounded, C.ok, C.okBg),
        const SizedBox(width: 12),
        _stat('Sparepart terlaris', '${r.summary['terlaris'] ?? '-'}', Icons.emoji_events_rounded, C.warn, C.warnBg),
      ]),
      const SectionTitle('Detail Sparepart'),
      if (r.partSales.isEmpty)
        _emptyCard()
      else
        for (var i = 0; i < r.partSales.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _rank(i + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.partSales[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      Text('${r.partSales[i].code} · ${r.partSales[i].category}', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                      Text(
                        [
                          if (showService) 'Service ${r.partSales[i].qtyService}',
                          if (showSales) 'Penjualan ${r.partSales[i].qtySales}',
                        ].join(' · '),
                        style: TextStyle(color: C.mutedOf(context), fontSize: 11.5),
                      ),
                      Text('Nilai ${rp(r.partSales[i].revenue)} · Laba ${rp(r.partSales[i].profit)}', style: const TextStyle(color: C.ok, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${r.partSales[i].qtyTotal}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: C.brandOf(context))),
                    Text('terjual', style: TextStyle(color: C.mutedOf(context), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
    ];
  }

  /// Laporan Loyalitas: pelanggan paling sering datang & belanja.
  List<Widget> _loyalty(_Report r) {
    final showService = _source != 'SALES';
    final showSales = _source != 'SERVICE';
    return [
      Row(children: [
        _stat('Total pelanggan', '${_s(r.summary, 'totalPelanggan').toInt()}', Icons.people_alt_rounded, C.brand, C.brand50),
        const SizedBox(width: 12),
        _stat('Total transaksi', '${_s(r.summary, 'totalTransaksi').toInt()}', Icons.receipt_long_rounded, C.violet, C.violetBg),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _stat('Rata-rata transaksi', '${_s(r.summary, 'rataTransaksi')}', Icons.bar_chart_rounded, const Color(0xFF0891B2), const Color(0xFFECFEFF)),
        const SizedBox(width: 12),
        _stat('Total belanja', rp(_s(r.summary, 'totalBelanja')), Icons.payments_rounded, C.ok, C.okBg),
      ]),
      const SectionTitle('Detail Pelanggan'),
      if (r.loyalty.isEmpty)
        _emptyCard()
      else
        for (var i = 0; i < r.loyalty.length; i++)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            onTap: () => go<dynamic>(context, CustomerDetailScreen(id: r.loyalty[i].customerId)),
            child: Row(
              children: [
                _rank(i + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.loyalty[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      Text(r.loyalty[i].phone, style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                      Text(
                        [
                          if (showService) 'Service ${r.loyalty[i].serviceCount}',
                          if (showSales) 'Penjualan ${r.loyalty[i].salesCount}',
                          '${r.loyalty[i].visits} transaksi',
                        ].join(' · '),
                        style: TextStyle(color: C.mutedOf(context), fontSize: 11.5),
                      ),
                      Text('Terakhir: ${fmtDate(r.loyalty[i].lastDate)}', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rp(r.loyalty[i].totalSpent), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: C.ok)),
                    const SizedBox(height: 4),
                    StatusChip(r.loyalty[i].active ? 'AKTIF' : 'NONAKTIF'),
                  ],
                ),
              ],
            ),
          ),
      Padding(
        padding: EdgeInsets.fromLTRB(2, 6, 2, 0),
        child: Text(
          'Transaksi = service lunas + pembelian sparepart atas nama pelanggan terdaftar. '
          'Status Nonaktif bila terakhir datang lebih dari 90 hari lalu.',
          style: TextStyle(color: C.mutedOf(context), fontSize: 11.5, height: 1.4),
        ),
      ),
    ];
  }

  List<Widget> _stock(_Report r) {
    final list = r.parts.where((p) => _stockFilter == 'ALL' || p.status == _stockFilter).toList();
    return [
      Row(children: [
        _stat('Total item', '${_s(r.summary, 'totalItems').toInt()}', Icons.inventory_2_rounded, C.brand, C.brand50),
        const SizedBox(width: 12),
        _stat('Nilai stok', rp(_s(r.summary, 'totalStockValue')), Icons.account_balance_wallet_rounded, C.ok, C.okBg),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _stat('Baik', '${_s(r.summary, 'baik').toInt()}', Icons.check_circle_rounded, C.ok, C.okBg),
        const SizedBox(width: 12),
        _stat('Rendah', '${_s(r.summary, 'rendah').toInt()}', Icons.warning_amber_rounded, C.warn, C.warnBg),
        const SizedBox(width: 12),
        _stat('Habis', '${_s(r.summary, 'habis').toInt()}', Icons.error_rounded, C.danger, C.dangerBg),
      ]),
      const SectionTitle('Detail Sparepart'),
      if (list.isEmpty)
        _emptyCard('Tidak ada data')
      else
        for (final p in list)
          AppCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      Text('${p.code} · ${p.categoryName}', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                      Text('Nilai ${rp(p.buyPrice * p.stock)}', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                    ],
                  ),
                ),
                Text('${p.stock}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: C.tone(context, statusColor(p.status)))),
                const SizedBox(width: 8),
                StatusChip(p.status),
              ],
            ),
          ),
    ];
  }
}
