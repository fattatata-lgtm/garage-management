import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  Future<void> _edit(BuildContext context, Category? cat) async {
    final ctrl = TextEditingController(text: cat?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(cat == null ? 'Kategori Baru' : 'Edit Kategori', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: LabeledField('Nama kategori', TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Contoh: Oli Mesin', icon: Icons.category_rounded))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || name.isEmpty) return;
    try {
      if (cat == null) {
        await Api.I.post('/categories', body: {'name': name});
      } else {
        await Api.I.put('/categories/${cat.id}', body: {'name': name});
      }
      Bus.bump();
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _delete(BuildContext context, Category cat) async {
    final ok = await confirmDialog(context, title: 'Hapus kategori?', message: '"${cat.name}" akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/categories/${cat.id}');
      Bus.bump();
    } on ApiException catch (e) {
      if (context.mounted) toast(context, cat.count > 0 ? 'Kategori masih dipakai ${cat.count} sparepart.' : e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Sparepart')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kategori'),
      ),
      body: AsyncBody<List<Category>>(
        refreshOn: Bus.tick,
        loader: () => Api.I.list('/categories', Category.fromJson),
        builder: (context, list, reload) {
          if (list.isEmpty) return emptyList(Icons.category_outlined, 'Belum ada kategori');
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              return AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                child: Row(
                  children: [
                    const IconTile(Icons.category_rounded, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${c.count} sparepart', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => _edit(context, c), icon: const Icon(Icons.edit_rounded, size: 20)),
                    IconButton(onPressed: () => _delete(context, c), icon: const Icon(Icons.delete_outline_rounded, size: 20, color: C.danger)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
