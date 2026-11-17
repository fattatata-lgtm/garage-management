import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';

/// Kartu satu transaksi service (dipakai di Dashboard, Daftar Layanan, Detail Pelanggan, dll).
class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.service, required this.onTap, this.margin = const EdgeInsets.only(bottom: 10)});
  final Service service;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final s = service;
    final v = s.vehicle;
    return AppCard(
      margin: margin,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(v?.isMotor == true ? Icons.two_wheeler_rounded : Icons.directions_car_rounded,
              color: statusColor(s.status), bg: statusBg(s.status)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PlateBadge(s.plate),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(v?.modelLabel ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.textOf(context))),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text('${s.ownerName}${s.technician != null ? ' · ${s.technician!.name}' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                const SizedBox(height: 2),
                Text('${fmtDate(s.date)} · ${s.invoiceNo}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(s.status),
              if (s.total > 0) ...[
                const SizedBox(height: 8),
                Text(rp(s.total), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: C.textOf(context))),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SparepartTile extends StatelessWidget {
  const SparepartTile({super.key, required this.sparepart, required this.onTap});
  final Sparepart sparepart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sp = sparepart;
    final c = C.tone(context, statusColor(sp.status));
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(Icons.settings_rounded, color: c, bg: statusBg(sp.status)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sp.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.textOf(context))),
                const SizedBox(height: 3),
                Text('${sp.code} · ${sp.categoryName}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                if (sp.supplierName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(children: [
                      Icon(Icons.local_shipping_rounded, size: 12, color: C.mutedOf(context)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(sp.supplierName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12))),
                    ]),
                  ),
                const SizedBox(height: 4),
                Text(rp(sp.sellPrice), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${sp.stock}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
              Text('stok', style: TextStyle(color: C.mutedOf(context), fontSize: 11)),
              if (sp.status != 'BAIK') ...[const SizedBox(height: 4), StatusChip(sp.status)],
            ],
          ),
        ],
      ),
    );
  }
}

class SaleTile extends StatelessWidget {
  const SaleTile({super.key, required this.sale, required this.onTap});
  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = sale;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          const IconTile(Icons.receipt_long_rounded, color: C.ok, bg: C.okBg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.customerName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.textOf(context))),
                const SizedBox(height: 3),
                Text(s.invoiceNo, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                const SizedBox(height: 2),
                Text('${fmtDateTime(s.date)}${s.items.isNotEmpty ? ' · ${s.itemCount} item' : ''}',
                    style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
              ],
            ),
          ),
          Text(rp(s.total), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: C.textOf(context))),
        ],
      ),
    );
  }
}

class CustomerTile extends StatelessWidget {
  const CustomerTile({super.key, required this.customer, required this.onTap});
  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Avatar(c.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.textOf(context))),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.phone_rounded, size: 13, color: C.mutedOf(context)),
                  const SizedBox(width: 4),
                  Text(c.phone, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: C.soft(context, C.brand50), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.directions_car_rounded, size: 14, color: C.brandOf(context)),
              const SizedBox(width: 4),
              Text('${c.vehicleCount}', style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800, fontSize: 12.5)),
            ]),
          ),
        ],
      ),
    );
  }
}

class VehicleTile extends StatelessWidget {
  const VehicleTile({super.key, required this.vehicle, required this.onTap, this.showOwner = true});
  final Vehicle vehicle;
  final VoidCallback onTap;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(v.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlateBadge(v.plateNumber),
                const SizedBox(height: 5),
                Text('${v.modelLabel}${v.model != null ? ' · ${v.model!.year}' : ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.textOf(context))),
                if (showOwner && v.customer != null) ...[
                  const SizedBox(height: 2),
                  Text(v.customer!.name, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: C.mutedOf(context)),
        ],
      ),
    );
  }
}
