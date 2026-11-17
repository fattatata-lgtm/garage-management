import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class ServiceTypeScreen extends StatefulWidget {
  const ServiceTypeScreen({super.key});

  @override
  State<ServiceTypeScreen> createState() => _ServiceTypeScreenState();
}

class _ServiceTypeScreenState extends State<ServiceTypeScreen> {
  String _q = '';

  Future<void> _edit(ServiceType? t) async {
    final name = TextEditingController(text: t?.name ?? '');
    final desc = TextEditingController(text: t?.description ?? '');
    final cost = TextEditingController(text: rpText(t?.estimatedCost));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t == null ? 'Jenis Layanan Baru' : 'Edit Jenis Layanan', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField('Nama layanan', TextField(controller: name, textCapitalization: TextCapitalization.sentences, decoration: deco(null, hint: 'Contoh: Servis Berkala'))),
              const SizedBox(height: 10),
              LabeledField('Deskripsi (opsional)', TextField(controller: desc, minLines: 2, maxLines: 3, decoration: deco(null, hint: 'Contoh: Ganti oli dan cek rem'))),
              const SizedBox(height: 10),
              LabeledField('Estimasi biaya', TextField(controller: cost, keyboardType: TextInputType.number, inputFormatters: [ThousandsFormatter()], decoration: deco(null, hint: 'Contoh: 150000', prefixText: 'Rp '))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    final body = {
      'name': name.text.trim(),
      'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
      'estimatedCost': parseRp(cost.text),
    };
    for (final c in [name, desc, cost]) {
      c.dispose();
    }
    if (ok != true || !mounted) return;
    if ((body['name'] as String).isEmpty) {
      toast(context, 'Nama layanan wajib diisi.', error: true);
      return;
    }
    try {
      if (t == null) {
        await Api.I.post('/service-types', body: body);
      } else {
        await Api.I.put('/service-types/${t.id}', body: body);
      }
      Bus.bump();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _delete(ServiceType t) async {
    final ok = await confirmDialog(context, title: 'Hapus layanan?', message: '"${t.name}" akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/service-types/${t.id}');
      Bus.bump();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jenis Layanan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, onPressed: () => _edit(null), icon: const Icon(Icons.add_rounded), label: const Text('Layanan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(hint: 'Cari layanan...', onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: AsyncBody<List<ServiceType>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/service-types', ServiceType.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((t) => q.isEmpty || t.name.toLowerCase().contains(q) || (t.description?.toLowerCase().contains(q) ?? false)).toList();
                if (list.isEmpty) return emptyList(Icons.miscellaneous_services_outlined, 'Belum ada jenis layanan');
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final t = list[i];
                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                if (t.description != null) Text(t.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                                const SizedBox(height: 3),
                                Text(rp(t.estimatedCost), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          IconButton(onPressed: () => _edit(t), icon: const Icon(Icons.edit_rounded, size: 20)),
                          IconButton(onPressed: () => _delete(t), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: C.danger)),
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
