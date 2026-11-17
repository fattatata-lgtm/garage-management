import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import '../../widgets/tiles.dart';
import 'vehicle_detail_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  String _q = '';

  // Filter Merk / Model / Roda (sama dengan website). Pilihannya berasal dari Master Kendaraan.
  String _brand = '';
  String _model = '';
  int? _wheels;
  List<VehicleModel> _masters = [];

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  Future<void> _loadMasters() async {
    try {
      final m = await Api.I.list('/vehicle-models', VehicleModel.fromJson);
      if (mounted) setState(() => _masters = m);
    } on ApiException {
      // Sama seperti website: bila master gagal dimuat, daftar tetap tampil tanpa pilihan filter.
    }
  }

  int _cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  List<String> get _brandOptions => _masters.map((m) => m.brand).toSet().toList()..sort(_cmp);

  List<String> get _modelOptions =>
      _masters.where((m) => _brand.isEmpty || m.brand == _brand).map((m) => m.model).toSet().toList()..sort(_cmp);

  List<int> get _wheelOptions => _masters.map((m) => m.wheels).toSet().toList()..sort();

  bool get _filterActive => _brand.isNotEmpty || _model.isNotEmpty || _wheels != null;

  void _setBrand(String v) {
    setState(() {
      _brand = v;
      // Model yang dipilih dikosongkan bila bukan milik merk baru.
      if (_model.isNotEmpty && v.isNotEmpty && !_masters.any((m) => m.brand == v && m.model == _model)) _model = '';
    });
  }

  void _resetFilters() => setState(() {
        _brand = '';
        _model = '';
        _wheels = null;
      });

  /// Pilih satu teks dari daftar. '' = "Semua", null = ditutup tanpa memilih.
  Future<String?> _pickText(String title, String allLabel, IconData icon, List<String> options) {
    return showPickerSheet<String>(
      context,
      title: title,
      items: options,
      matches: (o, q) => o.toLowerCase().contains(q),
      header: Builder(
        builder: (context) => ListTile(
          leading: Icon(icon, color: C.brandOf(context)),
          title: Text(allLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => Navigator.pop(context, ''),
        ),
      ),
      itemBuilder: (context, o) => Text(o, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          Widget clear(VoidCallback onClear) => GestureDetector(
                onTap: () {
                  onClear();
                  setModalState(() {});
                },
                child: const Icon(Icons.close_rounded, size: 20),
              );
          Widget chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
                label: Text(label),
                selected: sel,
                onSelected: (_) {
                  onTap();
                  setModalState(() {});
                },
                selectedColor: C.soft(context, C.brand50),
                labelStyle: TextStyle(color: sel ? C.brandOf(context) : C.textOf(context), fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
                side: BorderSide(color: sel ? C.brandOf(context) : C.lineOf(context)),
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
                      const Text('Filter Kendaraan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (_filterActive)
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
                  FieldTile(
                    label: 'Merk',
                    icon: Icons.sell_rounded,
                    value: _brand.isEmpty ? 'Semua Merk' : _brand,
                    trailing: _brand.isNotEmpty ? clear(() => _setBrand('')) : const Icon(Icons.keyboard_arrow_down_rounded),
                    onTap: () async {
                      final r = await _pickText('Filter Merk', 'Semua Merk', Icons.sell_rounded, _brandOptions);
                      if (r != null) _setBrand(r);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  FieldTile(
                    label: 'Model',
                    icon: Icons.directions_car_rounded,
                    value: _model.isEmpty ? 'Semua Model' : _model,
                    trailing: _model.isNotEmpty ? clear(() => setState(() => _model = '')) : const Icon(Icons.keyboard_arrow_down_rounded),
                    onTap: () async {
                      final r = await _pickText('Filter Model', 'Semua Model', Icons.directions_car_rounded, _modelOptions);
                      if (r != null) setState(() => _model = r);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 18),
                  Text('Roda', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('Semua Roda', _wheels == null, () => setState(() => _wheels = null)),
                      for (final w in _wheelOptions) chip('$w roda', _wheels == w, () => setState(() => _wheels = w)),
                    ],
                  ),
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

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  bool _passFilters(Vehicle v) {
    if (_brand.isNotEmpty && (v.model?.brand.toLowerCase() ?? '') != _brand.toLowerCase()) return false;
    if (_model.isNotEmpty && (v.model?.model.toLowerCase() ?? '') != _model.toLowerCase()) return false;
    if (_wheels != null && v.model?.wheels != _wheels) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Kendaraan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const VehicleFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kendaraan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(
              hint: 'Cari plat / VIN / nama pemilik...',
              onChanged: (v) => setState(() => _q = v),
              trailing: FilterIconButton(isActive: _filterActive, tooltip: 'Filter Kendaraan', onTap: _openFilterSheet),
            ),
          ),
          ActiveFilterBar(
            tags: [
              if (_brand.isNotEmpty) ('Merk: $_brand', () => _setBrand('')),
              if (_model.isNotEmpty) ('Model: $_model', () => setState(() => _model = '')),
              if (_wheels != null) ('Roda: $_wheels', () => setState(() => _wheels = null)),
            ],
            onClearAll: _resetFilters,
          ),
          Expanded(
            child: AsyncBody<List<Vehicle>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/vehicles', Vehicle.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all
                    .where(_passFilters)
                    .where((v) =>
                        q.isEmpty ||
                        v.plateNumber.toLowerCase().contains(q) ||
                        (v.vin?.toLowerCase().contains(q) ?? false) ||
                        (v.customer?.name.toLowerCase().contains(q) ?? false) ||
                        v.modelLabel.toLowerCase().contains(q))
                    .toList();
                if (list.isEmpty) return emptyList(Icons.directions_car_outlined, 'Kendaraan tidak ditemukan', _filterActive ? 'Ubah kata kunci atau filter.' : null);
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => VehicleTile(vehicle: list[i], onTap: () => _open(VehicleDetailScreen(id: list[i].id))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
