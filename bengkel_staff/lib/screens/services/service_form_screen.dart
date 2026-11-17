import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import '../vehicles/vehicle_form_screen.dart';
import 'service_detail_screen.dart';

/// Service diterima (tambah / edit data awal). Mengembalikan Service tersimpan.
class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key, this.service, this.vehicle});
  final Service? service;
  final Vehicle? vehicle;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _complaint = TextEditingController();
  Vehicle? _vehicle;
  Technician? _tech;
  DateTime _date = DateTime.now();
  bool _busy = false;
  bool _submitted = false;

  List<Vehicle>? _vehicles;
  List<Technician>? _techs;

  bool get _edit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      _vehicle = s.vehicle;
      _tech = s.technician;
      _date = s.date ?? DateTime.now();
      _complaint.text = s.complaint;
    } else {
      _vehicle = widget.vehicle;
    }
  }

  @override
  void dispose() {
    _complaint.dispose();
    super.dispose();
  }

  Future<void> _ensureVehicles({bool force = false}) async {
    if (_vehicles != null && !force) return;
    _vehicles = await Api.I.list('/vehicles', Vehicle.fromJson);
  }

  Future<void> _pickVehicle() async {
    try {
      await _ensureVehicles();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final v = await showPickerSheet<Vehicle>(
      context,
      title: 'Pilih Kendaraan',
      searchHint: 'Cari plat / pemilik...',
      items: _vehicles!,
      matches: (v, q) => v.plateNumber.toLowerCase().contains(q) || (v.customer?.name.toLowerCase().contains(q) ?? false) || v.modelLabel.toLowerCase().contains(q),
      itemBuilder: (context, v) => Row(
        children: [
          IconTile(v.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [PlateBadge(v.plateNumber), const SizedBox(width: 8), Flexible(child: Text(v.modelLabel, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)))]),
                const SizedBox(height: 3),
                Text(v.customer?.name ?? '-', style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
    if (v != null) setState(() => _vehicle = v);
  }

  Future<void> _addVehicle() async {
    final id = await go<int>(context, const VehicleFormScreen());
    if (id == null || !mounted) return;
    try {
      await _ensureVehicles(force: true);
      final found = _vehicles!.where((v) => v.id == id).toList();
      if (found.isNotEmpty && mounted) setState(() => _vehicle = found.first);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _pickTech() async {
    try {
      _techs ??= await Api.I.list('/technicians', Technician.fromJson, query: {'activeOnly': 'true'});
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final t = await showPickerSheet<Technician>(
      context,
      title: 'Pilih Teknisi',
      items: _techs!,
      matches: (t, q) => t.name.toLowerCase().contains(q) || (t.skill?.toLowerCase().contains(q) ?? false),
      itemBuilder: (context, t) => Row(
        children: [
          Avatar(t.name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (t.skill != null) Text(t.skill!, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
    if (t != null) setState(() => _tech = t);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_vehicle == null || _tech == null || _complaint.text.trim().isEmpty) {
      toast(context, 'Kendaraan, teknisi, tanggal, dan keluhan wajib diisi.', error: true);
      return;
    }
    setState(() => _busy = true);
    final body = {
      'vehicleId': _vehicle!.id,
      'technicianId': _tech!.id,
      'date': toApiDate(_date),
      'complaint': _complaint.text.trim(),
    };
    try {
      final d = _edit ? await Api.I.put('/services/${widget.service!.id}', body: body) : await Api.I.post('/services', body: body);
      Bus.bump();
      if (!mounted) return;
      final saved = Service.fromJson(Map<String, dynamic>.from(d as Map));
      if (_edit) {
        Navigator.pop(context, saved);
      } else {
        // Sama seperti web ("Simpan & Lanjut"): langsung buka detail service untuk tahap berikutnya
        toast(context, 'Service ${saved.invoiceNo} dibuat. Lanjutkan ke halaman detail.');
        Navigator.of(context).pushReplacement<void, Service>(
          MaterialPageRoute<void>(builder: (context) => ServiceDetailScreen(id: saved.id)),
          result: saved,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Data Service' : 'Service Baru')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FieldTile(
            label: 'Kendaraan',
            icon: Icons.directions_car_rounded,
            value: _vehicle == null ? null : '${_vehicle!.plateNumber} · ${_vehicle!.modelLabel}${_vehicle!.customer != null ? ' · ${_vehicle!.customer!.name}' : ''}',
            error: _submitted && _vehicle == null ? 'Pilih kendaraan' : null,
            onTap: _pickVehicle,
          ),
          if (_vehicle != null) ...[
            const SizedBox(height: 10),
            AppCard(
              color: C.soft(context, C.brand50),
              borderColor: C.soft(context, C.brand100),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconTile(_vehicle!.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_vehicle!.modelLabel}${_vehicle!.model != null ? ' (${_vehicle!.model!.year})' : ''}', style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            PlateBadge(_vehicle!.plateNumber),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  InfoRow('Nama pemilik', _vehicle!.customer?.name ?? '-'),
                  InfoRow('No. WhatsApp', _vehicle!.customer?.phone ?? '-'),
                  InfoRow('Warna', _vehicle!.color ?? '-'),
                ],
              ),
            ),
          ],
          if (!_edit)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addVehicle,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Kendaraan belum terdaftar? Tambah baru'),
              ),
            ),
          const SizedBox(height: 10),
          FieldTile(
            label: 'Teknisi',
            icon: Icons.engineering_rounded,
            value: _tech?.name,
            error: _submitted && _tech == null ? 'Pilih teknisi' : null,
            onTap: _pickTech,
          ),
          const SizedBox(height: 14),
          FieldTile(
            label: 'Tanggal Service',
            icon: Icons.calendar_today_rounded,
            value: fmtDate(_date),
            trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
            onTap: () async {
              final d = await pickDate(context, initial: _date);
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 14),
          LabeledField('Keluhan', TextField(
            controller: _complaint,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: deco(null, icon: Icons.chat_bubble_outline_rounded, hint: 'Contoh: mesin kasar, rem berdecit...').copyWith(
              errorText: _submitted && _complaint.text.trim().isEmpty ? 'Keluhan wajib diisi' : null,
            ),
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in const ['Servis rutin', 'Ganti oli', 'Rem berbunyi', 'Mesin brebet', 'Aki lemah', 'Ganti ban'])
                ActionChip(
                  label: Text(q, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  backgroundColor: C.cardOf(context),
                  side: BorderSide(color: C.lineOf(context)),
                  onPressed: () {
                    final base = _complaint.text.replaceAll(RegExp(r'[\s,.]+$'), '');
                    setState(() => _complaint.text = base.isEmpty ? q : '$base, ${q.toLowerCase()}');
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          ActionButton(label: _edit ? 'Simpan Perubahan' : 'Simpan & Lanjut', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
