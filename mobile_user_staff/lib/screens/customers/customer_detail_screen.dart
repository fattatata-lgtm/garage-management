import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/launchers.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import '../sales/sales_form_screen.dart';
import '../services/service_detail_screen.dart';
import '../services/service_form_screen.dart';
import '../vehicles/vehicle_detail_screen.dart';
import '../vehicles/vehicle_form_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Future<void> _delete(Customer c) async {
    final ok = await confirmDialog(context,
        title: 'Hapus pelanggan?', message: '${c.name} beserta kendaraannya akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/customers/${c.id}');
      Bus.bump();
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Customer>(
      fullScreen: true,
      refreshOn: Bus.tick,
      loader: () => Api.I.one('/customers/${widget.id}', Customer.fromJson),
      builder: (context, c, reload) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Pelanggan'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  final r = await go<Customer>(context, CustomerFormScreen(customer: c));
                  if (r != null) reload();
                },
              ),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.danger), onPressed: () => _delete(c)),
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
                        Avatar(c.name, size: 58),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(c.phone, style: TextStyle(color: C.mutedOf(context))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ActionButton(label: 'Telepon', icon: Icons.phone_rounded, kind: BtnKind.secondary, onPressed: () => callPhone(c.phone))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ActionButton(
                            label: 'WhatsApp',
                            icon: Icons.chat_rounded,
                            kind: BtnKind.success,
                            onPressed: () async {
                              final ok = await openWhatsApp(c.phone, 'Halo ${c.name}, ');
                              if (!ok && context.mounted) toast(context, 'Tidak dapat membuka WhatsApp.', error: true);
                            },
                          ),
                        ),
                      ],
                    ),
                    if ((c.email ?? '').isNotEmpty || (c.address ?? '').isNotEmpty) const Divider(height: 26),
                    if ((c.email ?? '').isNotEmpty) InfoRow('Email', c.email!),
                    if ((c.address ?? '').isNotEmpty) InfoRow('Alamat', c.address!),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Service',
                      icon: Icons.build_circle_rounded,
                      kind: BtnKind.tonal,
                      onPressed: () async {
                        if (c.vehicles.isEmpty) {
                          toast(context, 'Tambahkan kendaraan pelanggan terlebih dulu.', error: true);
                          return;
                        }
                        final v = c.vehicles.first;
                        final withCustomer = Vehicle(
                          id: v.id, customerId: v.customerId, vehicleModelId: v.vehicleModelId, plateNumber: v.plateNumber,
                          vin: v.vin, engineNumber: v.engineNumber, color: v.color, purchaseYear: v.purchaseYear, note: v.note,
                          customer: c, model: v.model,
                        );
                        final r = await go<Service>(context, ServiceFormScreen(vehicle: withCustomer));
                        if (r != null) reload();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionButton(
                      label: 'Penjualan',
                      icon: Icons.point_of_sale_rounded,
                      kind: BtnKind.tonal,
                      onPressed: () async {
                        await go<dynamic>(context, SalesFormScreen(customer: c));
                        reload();
                      },
                    ),
                  ),
                ],
              ),
              SectionTitle('Kendaraan (${c.vehicles.length})',
                  action: '+ Tambah',
                  onAction: () async {
                    final id = await go<int>(context, VehicleFormScreen(customer: c));
                    if (id != null) reload();
                  }),
              if (c.vehicles.isEmpty)
                AppCard(child: Center(child: Text('Belum ada kendaraan', style: TextStyle(color: C.mutedOf(context)))))
              else
                for (final v in c.vehicles)
                  VehicleTile(
                    vehicle: v,
                    showOwner: false,
                    onTap: () async {
                      await go<dynamic>(context, VehicleDetailScreen(id: v.id));
                      reload();
                    },
                  ),
              SectionTitle('Riwayat Service (${c.serviceHistory.length})'),
              if (c.serviceHistory.isEmpty)
                AppCard(child: Center(child: Text('Belum ada riwayat service', style: TextStyle(color: C.mutedOf(context)))))
              else
                for (final s in c.serviceHistory)
                  ServiceTile(service: s, onTap: () => go<dynamic>(context, ServiceDetailScreen(id: s.id))),
            ],
          ),
        );
      },
    );
  }
}
