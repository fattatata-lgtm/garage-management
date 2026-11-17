import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';

/// Tambah / edit kendaraan. Mengembalikan id kendaraan (int) bila tersimpan.
class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle, this.customer});
  final Vehicle? vehicle;
  final Customer? customer;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _plate = TextEditingController(text: widget.vehicle?.plateNumber ?? '');
  late final TextEditingController _vin = TextEditingController(text: widget.vehicle?.vin ?? '');
  late final TextEditingController _engine = TextEditingController(text: widget.vehicle?.engineNumber ?? '');
  late final TextEditingController _color = TextEditingController(text: widget.vehicle?.color ?? '');
  late final TextEditingController _year = TextEditingController(text: widget.vehicle?.purchaseYear?.toString() ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.vehicle?.note ?? '');
  Customer? _customer;
  VehicleModel? _model;
  List<Customer>? _customers;
  List<VehicleModel>? _models;
  bool _busy = false;
  bool _submitted = false;

  bool get _edit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _customer = widget.vehicle?.customer ?? widget.customer;
    _model = widget.vehicle?.model;
  }

  @override
  void dispose() {
    for (final c in [_plate, _vin, _engine, _color, _year, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    try {
      _customers ??= await Api.I.list('/customers', Customer.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final c = await showPickerSheet<Customer>(
      context,
      title: 'Pilih Pemilik',
      searchHint: 'Cari nama / No. HP...',
      items: _customers!,
      matches: (c, q) => c.name.toLowerCase().contains(q) || c.phone.contains(q),
      itemBuilder: (context, c) => Row(children: [
        Avatar(c.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(c.phone, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
          ]),
        ),
      ]),
    );
    if (c != null) setState(() => _customer = c);
  }

  Future<void> _pickModel() async {
    try {
      _models ??= await Api.I.list('/vehicle-models', VehicleModel.fromJson);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
      return;
    }
    if (!mounted) return;
    final m = await showPickerSheet<VehicleModel>(
      context,
      title: 'Pilih Jenis Kendaraan',
      searchHint: 'Cari merk / model...',
      items: _models!,
      matches: (m, q) => m.label.toLowerCase().contains(q) || m.type.toLowerCase().contains(q) || '${m.year}'.contains(q),
      itemBuilder: (context, m) => Row(children: [
        IconTile(m.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.label, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${m.year} · ${m.type} · ${m.wheels} roda', style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
          ]),
        ),
      ]),
    );
    if (m != null) setState(() => _model = m);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate() || _customer == null || _model == null) return;
    setState(() => _busy = true);
    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final body = {
      'customerId': _customer!.id,
      'vehicleModelId': _model!.id,
      'plateNumber': _plate.text.trim().toUpperCase(),
      'vin': opt(_vin),
      'engineNumber': opt(_engine),
      'color': opt(_color),
      'purchaseYear': int.tryParse(_year.text.trim()),
      'note': opt(_note),
    };
    try {
      final d = _edit ? await Api.I.put('/vehicles/${widget.vehicle!.id}', body: body) : await Api.I.post('/vehicles', body: body);
      Bus.bump();
      final id = int.tryParse('${(d as Map)['id']}') ?? widget.vehicle?.id ?? 0;
      if (mounted) Navigator.pop(context, id);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message.contains('Unique') ? 'No. plat sudah terdaftar.' : e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Kendaraan' : 'Kendaraan Baru')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            FieldTile(label: 'Pemilik', icon: Icons.person_rounded, value: _customer?.name, error: _submitted && _customer == null ? 'Pilih pemilik' : null, onTap: _pickCustomer),
            const SizedBox(height: 14),
            FieldTile(label: 'Jenis kendaraan', icon: Icons.directions_car_rounded, value: _model == null ? null : '${_model!.label} · ${_model!.year}', error: _submitted && _model == null ? 'Pilih jenis kendaraan' : null, onTap: _pickModel),
            const SizedBox(height: 14),
            LabeledField('No. Plat', TextFormField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: deco(null, icon: Icons.pin_rounded, hint: 'N 1234 AB'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'No. plat wajib diisi' : null,
            )),
            const SizedBox(height: 14),
            LabeledField('No. Rangka / VIN (opsional)', TextFormField(controller: _vin, textCapitalization: TextCapitalization.characters, decoration: deco(null, hint: 'Contoh: MHKA1BA1JGK000123', icon: Icons.tag_rounded))),
            const SizedBox(height: 14),
            LabeledField('No. Mesin (opsional)', TextFormField(controller: _engine, textCapitalization: TextCapitalization.characters, decoration: deco(null, hint: 'Contoh: 1NRF123456', icon: Icons.settings_rounded))),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: LabeledField('Warna', TextFormField(controller: _color, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Contoh: Hitam', icon: Icons.palette_rounded)))),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField('Thn Beli', TextFormField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    decoration: deco(null, hint: 'Contoh: 2022', icon: Icons.event_rounded),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LabeledField('Catatan (opsional)', TextFormField(controller: _note, minLines: 2, maxLines: 4, decoration: deco(null, hint: 'Catatan tambahan', icon: Icons.notes_rounded))),
            const SizedBox(height: 24),
            ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
