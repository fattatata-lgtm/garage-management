import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Data Master Kendaraan: merk, model, tahun, tipe, jumlah roda.
class VehicleMasterScreen extends StatefulWidget {
  const VehicleMasterScreen({super.key});

  @override
  State<VehicleMasterScreen> createState() => _VehicleMasterScreenState();
}

class _VehicleMasterScreenState extends State<VehicleMasterScreen> {
  String _q = '';

  Future<void> _edit(VehicleModel? m) async {
    final brand = TextEditingController(text: m?.brand ?? '');
    final model = TextEditingController(text: m?.model ?? '');
    final year = TextEditingController(text: m?.year.toString() ?? '${DateTime.now().year}');
    final type = TextEditingController(text: m?.type ?? '');
    int wheels = m?.wheels ?? 4;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(m == null ? 'Master Kendaraan Baru' : 'Edit Master', style: const TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledField('Merk', TextField(controller: brand, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Toyota'))),
                const SizedBox(height: 10),
                LabeledField('Model', TextField(controller: model, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Avanza'))),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: LabeledField('Tahun', TextField(controller: year, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], decoration: deco(null, hint: 'Contoh: 2020')))),
                  const SizedBox(width: 10),
                  Expanded(child: LabeledField('Tipe', TextField(controller: type, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'MPV')))),
                ]),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 2, label: Text('2 Roda'), icon: Icon(Icons.two_wheeler_rounded)),
                    ButtonSegment(value: 4, label: Text('4 Roda'), icon: Icon(Icons.directions_car_rounded)),
                  ],
                  selected: {wheels},
                  onSelectionChanged: (s) => setD(() => wheels = s.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    final body = {
      'brand': brand.text.trim(),
      'model': model.text.trim(),
      'year': int.tryParse(year.text.trim()),
      'type': type.text.trim(),
      'wheels': wheels,
    };
    for (final c in [brand, model, year, type]) {
      c.dispose();
    }
    if (ok != true) return;
    if (!mounted) return;
    if ((body['brand'] as String).isEmpty || (body['model'] as String).isEmpty || body['year'] == null || (body['type'] as String).isEmpty) {
      toast(context, 'Merk, model, tahun, dan tipe wajib diisi.', error: true);
      return;
    }
    try {
      if (m == null) {
        await Api.I.post('/vehicle-models', body: body);
      } else {
        await Api.I.put('/vehicle-models/${m.id}', body: body);
      }
      Bus.bump();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _delete(VehicleModel m) async {
    final ok = await confirmDialog(context, title: 'Hapus master?', message: '${m.label} (${m.year}) akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/vehicle-models/${m.id}');
      Bus.bump();
    } on ApiException catch (e) {
      if (mounted) toast(context, 'Tidak dapat dihapus: masih dipakai data kendaraan.', error: true);
      debugPrint(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Kendaraan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, onPressed: () => _edit(null), icon: const Icon(Icons.add_rounded), label: const Text('Master')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(hint: 'Cari merk / model...', onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: AsyncBody<List<VehicleModel>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/vehicle-models', VehicleModel.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((m) => q.isEmpty || m.label.toLowerCase().contains(q) || m.type.toLowerCase().contains(q)).toList();
                if (list.isEmpty) return emptyList(Icons.directions_car_outlined, 'Belum ada data master');
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                      child: Row(
                        children: [
                          IconTile(m.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text('${m.year} · ${m.type} · ${m.wheels} roda', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => _edit(m), icon: const Icon(Icons.edit_rounded, size: 20)),
                          IconButton(onPressed: () => _delete(m), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: C.danger)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
