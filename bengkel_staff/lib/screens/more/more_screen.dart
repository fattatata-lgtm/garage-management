import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_provider.dart';
import '../../core/nav.dart';
import '../../core/settings_provider.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../customers/customer_list_screen.dart';
import '../discounts/discount_screens.dart';
import '../login_screen.dart' show ServerSheet;
import '../spareparts/category_screen.dart';
import '../spareparts/stock_history_screen.dart';
import '../suppliers/supplier_screens.dart';
import '../vehicles/vehicle_list_screen.dart';
import '../vehicles/vehicle_master_screen.dart';
import 'app_settings_screen.dart';
import 'reports_screen.dart';
import 'service_type_screen.dart';
import 'technician_screens.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Widget _item(BuildContext context, IconData icon, String label, String sub, Widget page, {Color color = C.brand, Color bg = C.brand50}) {
    return InkWell(
      onTap: () => go<dynamic>(context, page),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            IconTile(icon, color: color, bg: bg, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  Text(sub, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: C.mutedOf(context)),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 72, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final st = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: C.heroOf(context), borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
                  child: Text((user?.username ?? '?').substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.username ?? '-', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(user?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                        child: Text('${user?.roleLabel ?? ''} · ${st.businessName}', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _group('Data', [
            _item(context, Icons.people_alt_rounded, 'Pelanggan', 'Data pelanggan & riwayat', const CustomerListScreen()),
            _item(context, Icons.directions_car_rounded, 'Data Kendaraan', 'Kendaraan milik pelanggan', const VehicleListScreen(), color: const Color(0xFF0891B2), bg: const Color(0xFFECFEFF)),
            _item(context, Icons.engineering_rounded, 'Teknisi', 'Jadwal & riwayat teknisi', const TechnicianListScreen(), color: C.violet, bg: C.violetBg),
            _item(context, Icons.local_shipping_rounded, 'Supplier', 'Pemasok sparepart', const SupplierListScreen(), color: C.warn, bg: C.warnBg),
          ]),
          _group('Master', [
            _item(context, Icons.miscellaneous_services_rounded, 'Jenis Layanan', 'Daftar jasa & estimasi biaya', const ServiceTypeScreen()),
            _item(context, Icons.directions_car_filled_rounded, 'Master Kendaraan', 'Merk, model & tipe', const VehicleMasterScreen()),
            _item(context, Icons.percent_rounded, 'Diskon', 'Promo & kupon', const DiscountListScreen(), color: C.violet, bg: C.violetBg),
            _item(context, Icons.category_rounded, 'Kategori Sparepart', 'Kelompok sparepart', const CategoryScreen(), color: C.warn, bg: C.warnBg),
            _item(context, Icons.history_rounded, 'Riwayat Stok', 'Stok masuk & keluar', const StockHistoryScreen(), color: C.ok, bg: C.okBg),
          ]),
          _group('Laporan', [
            _item(context, Icons.build_rounded, 'Laporan Layanan', 'Rekap service & layanan terlaris', const ReportsScreen(initialTab: kTabService)),
            _item(context, Icons.point_of_sale_rounded, 'Laporan Penjualan', 'Rekap penjualan & laba', const ReportsScreen(initialTab: kTabSales), color: C.ok, bg: C.okBg),
            _item(context, Icons.settings_rounded, 'Laporan Sparepart', 'Sparepart paling laris', const ReportsScreen(initialTab: kTabSparepart), color: const Color(0xFF0891B2), bg: const Color(0xFFECFEFF)),
            _item(context, Icons.volunteer_activism_rounded, 'Laporan Loyalitas', 'Pelanggan setia', const ReportsScreen(initialTab: kTabLoyalty), color: C.violet, bg: C.violetBg),
            _item(context, Icons.inventory_2_rounded, 'Laporan Stok', 'Nilai & status stok', const ReportsScreen(initialTab: kTabStock), color: C.warn, bg: C.warnBg),
          ]),
          const SectionTitle('Aplikasi'),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _item(context, Icons.tune_rounded, 'Pengaturan Aplikasi', 'Logo, pajak, mode malam, printer', const AppSettingsScreen()),
                const Divider(height: 1, indent: 72, endIndent: 16),
                InkWell(
                  onTap: () => showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const ServerSheet()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const IconTile(Icons.dns_rounded, color: C.muted, bg: Color(0xFFF1F5F9), size: 42),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alamat Server', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                              Text(Store.serverUrl, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 72, endIndent: 16),
                InkWell(
                  onTap: () async {
                    final ok = await confirmDialog(context, title: 'Keluar?', message: 'Anda harus login kembali untuk memakai aplikasi.', okLabel: 'Keluar', danger: true);
                    if (ok && context.mounted) context.read<AuthProvider>().logout();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconTile(Icons.logout_rounded, color: C.danger, bg: C.dangerBg, size: 42),
                        SizedBox(width: 14),
                        Text('Keluar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.danger)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
