import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import '../services/service_detail_screen.dart';
import '../services/service_form_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleDetailScreen extends StatelessWidget {
  const VehicleDetailScreen({super.key, required this.id});
  final int id;

  Future<void> _delete(BuildContext context, Vehicle v) async {
    final ok = await confirmDialog(context, title: 'Hapus kendaraan?', message: '${v.plateNumber} akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/vehicles/${v.id}');
      Bus.bump();
      if (context.mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Vehicle>(
      fullScreen: true,
      refreshOn: Bus.tick,
      loader: () => Api.I.one('/vehicles/$id', Vehicle.fromJson),
      builder: (context, v, reload) => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Kendaraan'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                final r = await go<int>(context, VehicleFormScreen(vehicle: v));
                if (r != null) reload();
              },
            ),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.danger), onPressed: () => _delete(context, v)),
          ],
        ),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconTile(v.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlateBadge(v.plateNumber),
                            const SizedBox(height: 6),
                            Text(v.modelLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (v.model != null) ...[
                    InfoRow('Tahun model', '${v.model!.year}'),
                    InfoRow('Tipe', v.model!.type),
                  ],
                  InfoRow('Warna', v.color ?? '-'),
                  InfoRow('No. Rangka', v.vin ?? '-'),
                  InfoRow('No. Mesin', v.engineNumber ?? '-'),
                  InfoRow('Tahun beli', v.purchaseYear?.toString() ?? '-'),
                  if (v.note != null) InfoRow('Catatan', v.note!),
                ],
              ),
            ),
            if (v.customer != null)
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Avatar(v.customer!.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pemilik', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                          Text(v.customer!.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(v.customer!.phone, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ActionButton(
              label: 'Buat Service untuk Kendaraan Ini',
              icon: Icons.build_circle_rounded,
              onPressed: () async {
                final r = await go<Service>(context, ServiceFormScreen(vehicle: v));
                if (r != null) reload();
              },
            ),
            SectionTitle('Riwayat Service (${v.services.length})'),
            if (v.services.isEmpty)
              AppCard(child: Center(child: Text('Belum ada riwayat service', style: TextStyle(color: C.mutedOf(context)))))
            else
              for (final s in v.services)
                ServiceTile(
                  service: Service(
                    id: s.id, invoiceNo: s.invoiceNo, date: s.date, km: s.km, complaint: s.complaint, internalNote: s.internalNote,
                    status: s.status, nextRecommendation: s.nextRecommendation, subtotal: s.subtotal, discountAmount: s.discountAmount,
                    taxAmount: s.taxAmount, total: s.total, paid: s.paid, change: s.change, vehicle: v, technician: s.technician,
                  ),
                  onTap: () => go<dynamic>(context, ServiceDetailScreen(id: s.id)),
                ),
          ],
        ),
      ),
    );
  }
}
