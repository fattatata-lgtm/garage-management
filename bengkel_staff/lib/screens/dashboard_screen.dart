import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_provider.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/nav.dart';
import '../core/settings_provider.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'more/app_settings_screen.dart';
import '../widgets/tiles.dart';
import 'customers/customer_list_screen.dart';
import 'sales/sales_form_screen.dart';
import 'services/service_detail_screen.dart';
import 'services/service_form_screen.dart';
import 'spareparts/sparepart_detail_screen.dart';
import 'spareparts/sparepart_list_screen.dart';
import 'suppliers/supplier_screens.dart';
import 'vehicles/vehicle_list_screen.dart';
import 'more/technician_screens.dart';

class _DashData {
  _DashData(this.summary, this.diterima, this.dikerjakan, this.tagihan);
  final DashboardSummary summary;
  final List<Service> diterima;
  final List<Service> dikerjakan;
  final List<Service> tagihan;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _periods = <(String, String)>[('day', 'Hari Ini'), ('week', 'Minggu Ini'), ('month', 'Bulan Ini')];

  String _period = 'day';
  final _key = GlobalKey<AsyncBodyState<_DashData>>();

  Future<_DashData> _load() async {
    final r = await Future.wait<dynamic>([
      Api.I.one('/dashboard/summary', DashboardSummary.fromJson, query: {'period': _period}),
      Api.I.list('/services', Service.fromJson, query: {'status': 'DITERIMA'}),
      Api.I.list('/services', Service.fromJson, query: {'status': 'DIKERJAKAN'}),
      Api.I.list('/services', Service.fromJson, query: {'status': 'MENUNGGU_PEMBAYARAN'}),
    ]);
    return _DashData(
      r[0] as DashboardSummary,
      r[1] as List<Service>,
      r[2] as List<Service>,
      r[3] as List<Service>,
    );
  }

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: AsyncBody<_DashData>(
        key: _key,
        refreshOn: Bus.tick,
        loader: _load,
        builder: (context, d, reload) => ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _header(context, d),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Aksi Cepat', padding: EdgeInsets.fromLTRB(2, 0, 2, 10)),
                  _quickActions(context),
                  const SectionTitle('Antrian Service'),
                  _queue(d),
                  _stats(context, d.summary),
                  if (d.summary.lowStockAlerts.isNotEmpty) ...[
                    SectionTitle('Stok Perlu Perhatian', action: 'Lihat semua', onAction: () => AppNav.openStock('ALERT')),
                    _stockAlerts(context, d.summary.lowStockAlerts),
                  ],
                  SectionTitle('Service Terbaru', action: 'Semua', onAction: () => AppNav.openServices()),
                  if (d.summary.recentServices.isEmpty)
                    AppCard(child: Center(child: Text('Belum ada service', style: TextStyle(color: C.mutedOf(context)))))
                  else
                    ...d.summary.recentServices.take(5).map((s) => ServiceTile(service: s, onTap: () => _open(ServiceDetailScreen(id: s.id)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ Header + kartu pendapatan

  Widget _header(BuildContext context, _DashData d) {
    final user = context.watch<AuthProvider>().user;
    final st = context.watch<SettingsProvider>();
    final s = d.summary;
    final total = s.totalPendapatan;
    final svcFlex = total <= 0 ? 500 : ((s.pendapatanService / total) * 1000).round().clamp(1, 999);
    final periodLabel = _periods.firstWhere((p) => p.$1 == _period).$2;

    return Container(
      decoration: BoxDecoration(
        gradient: C.heroOf(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: C.isDark(context) ? D.surface2 : Colors.white, borderRadius: BorderRadius.circular(15)),
                child: st.logo.isNotEmpty
                    ? Image.network(st.logo, key: ValueKey(st.logo), fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.build_rounded, color: C.brandOf(context)))
                    : Icon(Icons.build_rounded, color: C.brandOf(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${greeting()} 👋', style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(user?.username ?? 'Staff',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withAlpha(36),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => go<dynamic>(context, const AppSettingsScreen()),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Tooltip(message: 'Pengaturan', child: Icon(Icons.settings_rounded, color: Colors.white, size: 23)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Pemilih periode
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: _periods.map((p) {
                final sel = p.$1 == _period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_period == p.$1) return;
                      setState(() => _period = p.$1);
                      _key.currentState?.reload();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: sel ? (C.isDark(context) ? D.surface2 : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Text(p.$2, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: sel ? C.brandOf(context) : Colors.white70)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Kartu total pendapatan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withAlpha(46)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Pendapatan · $periodLabel', style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _CountUp(value: total, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        Expanded(flex: svcFlex, child: Container(color: const Color(0xFF5EEAD4))),
                        const SizedBox(width: 2),
                        Expanded(flex: 1000 - svcFlex, child: Container(color: C.accent)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _legend(const Color(0xFF5EEAD4), 'Service', s.pendapatanService)),
                    Expanded(child: _legend(C.accent, 'Penjualan', s.pendapatanSales)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(color: Colors.black.withAlpha(36), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF86EFAC), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Estimasi laba penjualan', style: TextStyle(color: Colors.white70, fontSize: 12.5))),
                      Text(rp(s.labaEstimasi), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color c, String label, num value) {
    return Row(
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
              Text(rpShort(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ Aksi cepat

  Widget _quickActions(BuildContext context) {
    Widget item(IconData icon, String label, Color color, Color bg, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: C.soft(context, bg),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(icon, color: C.tone(context, color), size: 27),
              ),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.textOf(context))),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              item(Icons.build_circle_rounded, 'Service\nBaru', C.brand, C.brand50, () => _open(const ServiceFormScreen())),
              item(Icons.point_of_sale_rounded, 'Jual\nSparepart', C.ok, C.okBg, () => _open(const SalesFormScreen())),
              item(Icons.people_alt_rounded, 'Pelanggan', C.violet, C.violetBg, () => _open(const CustomerListScreen())),
              item(Icons.inventory_2_rounded, 'Sparepart', C.info, C.infoBg, () => AppNav.openStock()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              item(Icons.local_shipping_rounded, 'Supplier', C.brand, C.brand50, () => _open(const SupplierListScreen())),
              item(Icons.qr_code_scanner_rounded, 'Scan\nStok', C.warn, C.warnBg, () => scanAndOpenSparepart(context)),
              item(Icons.directions_car_rounded, 'Kendaraan', C.cyan, C.cyanBg, () => _open(const VehicleListScreen())),
              item(Icons.engineering_rounded, 'Teknisi', C.violet, C.violetBg, () => _open(const TechnicianListScreen())),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ Antrian & statistik

  Widget _queue(_DashData d) {
    Widget cell(String status, String label, int n, IconData icon) {
      final c = C.tone(context, statusColor(status));
      return Expanded(
        child: GestureDetector(
          onTap: () => AppNav.openServices(status),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: c),
                  const SizedBox(width: 6),
                  Text('$n', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: c)),
                ],
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          cell('DITERIMA', 'Diterima', d.diterima.length, Icons.inbox_rounded),
          Container(width: 1, height: 44, color: C.lineOf(context)),
          cell('DIKERJAKAN', 'Dikerjakan', d.dikerjakan.length, Icons.build_rounded),
          Container(width: 1, height: 44, color: C.lineOf(context)),
          cell('MENUNGGU_PEMBAYARAN', 'Tagihan', d.tagihan.length, Icons.payments_rounded),
        ],
      ),
    );
  }

  Widget _stats(BuildContext context, DashboardSummary s) {
    Widget tile(IconData icon, Color c, Color bg, String label, String value, VoidCallback? onTap) {
      return Expanded(
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon, color: c, bg: bg, size: 38),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.textOf(context))),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: C.mutedOf(context), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final kritis = s.lowStockAlerts.length;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            children: [
              tile(Icons.people_alt_rounded, C.brand, C.brand50, 'Pelanggan', '${s.totalCustomers}', () => go<dynamic>(context, const CustomerListScreen())),
              const SizedBox(width: 12),
              tile(Icons.directions_car_rounded, const Color(0xFF0891B2), const Color(0xFFECFEFF), 'Kendaraan', '${s.totalVehicles}', null),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              tile(Icons.build_rounded, C.violet, C.violetBg, 'Service periode ini', '${s.totalServices}', () => AppNav.openServices()),
              const SizedBox(width: 12),
              tile(Icons.warning_amber_rounded, kritis > 0 ? C.danger : C.ok, kritis > 0 ? C.dangerBg : C.okBg, 'Stok kritis', '$kritis',
                  () => AppNav.openStock('ALERT')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockAlerts(BuildContext context, List<Sparepart> alerts) {
    final sorted = [...alerts]..sort((a, b) {
        if (a.status == 'HABIS' && b.status != 'HABIS') return -1;
        if (a.status != 'HABIS' && b.status == 'HABIS') return 1;
        return a.stock.compareTo(b.stock);
      });
    final top = sorted.take(5).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            InkWell(
              onTap: () => go<dynamic>(context, SparepartDetailScreen(id: top[i].id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(top[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(top[i].code, style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                        ],
                      ),
                    ),
                    Text('${top[i].stock}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.tone(context, statusColor(top[i].status)))),
                    const SizedBox(width: 10),
                    StatusChip(top[i].status),
                  ],
                ),
              ),
            ),
            if (i < top.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});
  final num value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(rp(v), style: style),
      ),
    );
  }
}
