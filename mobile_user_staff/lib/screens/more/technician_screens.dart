import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import '../services/service_detail_screen.dart';

class TechnicianListScreen extends StatefulWidget {
  const TechnicianListScreen({super.key});

  @override
  State<TechnicianListScreen> createState() => _TechnicianListScreenState();
}

class _TechnicianListScreenState extends State<TechnicianListScreen> {
  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teknisi')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => editTechnician(context, null),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Teknisi'),
      ),
      body: AsyncBody<List<Technician>>(
        refreshOn: Bus.tick,
        loader: () => Api.I.list('/technicians', Technician.fromJson),
        builder: (context, list, reload) {
          if (list.isEmpty) return emptyList(Icons.engineering_outlined, 'Belum ada teknisi');
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return AppCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                onTap: () => _open(TechnicianDetailScreen(id: t.id)),
                child: Row(
                  children: [
                    Avatar(t.name),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          Text(t.skill ?? 'Mekanik', style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                          const SizedBox(height: 3),
                          Text('${t.serviceCount} service · ${t.scheduleCount} jadwal', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                        ],
                      ),
                    ),
                    StatusChip(t.status),
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

/// Dialog tambah/edit teknisi. Mengembalikan true bila tersimpan.
Future<bool> editTechnician(BuildContext context, Technician? t) async {
  final name = TextEditingController(text: t?.name ?? '');
  final skill = TextEditingController(text: t?.skill ?? '');
  bool aktif = t?.aktif ?? true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setD) => AlertDialog(
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t == null ? 'Teknisi Baru' : 'Edit Teknisi', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledField('Nama teknisi', TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: deco(null, hint: 'Contoh: Andi Pratama', icon: Icons.person_rounded))),
            const SizedBox(height: 10),
            LabeledField('Keahlian (opsional)', TextField(controller: skill, decoration: deco(null, hint: 'Contoh: Mesin, kelistrikan', icon: Icons.handyman_rounded))),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif', style: TextStyle(fontWeight: FontWeight.w700)),
              value: aktif,
              onChanged: (v) => setD(() => aktif = v),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    ),
  );
  final body = {
    'name': name.text.trim(),
    'skill': skill.text.trim().isEmpty ? null : skill.text.trim(),
    'status': aktif ? 'AKTIF' : 'NONAKTIF',
  };
  name.dispose();
  skill.dispose();
  if (ok != true || !context.mounted) return false;
  if ((body['name'] as String).isEmpty) {
    toast(context, 'Nama teknisi wajib diisi.', error: true);
    return false;
  }
  try {
    if (t == null) {
      await Api.I.post('/technicians', body: body);
    } else {
      await Api.I.put('/technicians/${t.id}', body: body);
    }
    Bus.bump();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
    return false;
  }
}

class TechnicianDetailScreen extends StatelessWidget {
  const TechnicianDetailScreen({super.key, required this.id});
  final int id;

  Future<void> _schedule(BuildContext context, Technician t, Schedule? sc, VoidCallback reload) async {
    DateTime date = sc?.date ?? DateTime.now();
    final note = TextEditingController(text: sc?.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(sc == null ? 'Tambah Jadwal' : 'Ubah Jadwal', style: const TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FieldTile(
                label: 'Tanggal',
                icon: Icons.event_rounded,
                value: fmtDate(date),
                onTap: () async {
                  final d = await pickDate(context, initial: date);
                  if (d != null) setD(() => date = d);
                },
              ),
              const SizedBox(height: 10),
              LabeledField('Catatan (opsional)', TextField(controller: note, decoration: deco(null, hint: 'Catatan tambahan', icon: Icons.notes_rounded))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    final n = note.text.trim();
    note.dispose();
    if (ok != true || !context.mounted) return;
    final body = {'date': toApiNoon(date), 'note': n.isEmpty ? null : n};
    try {
      if (sc == null) {
        await Api.I.post('/technicians/${t.id}/schedules', body: body);
      } else {
        await Api.I.put('/technicians/${t.id}/schedules/${sc.id}', body: body);
      }
      reload();
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _deleteSchedule(BuildContext context, Technician t, Schedule sc, VoidCallback reload) async {
    final ok = await confirmDialog(context, title: 'Hapus jadwal?', message: 'Jadwal ${fmtDate(sc.date)} akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/technicians/${t.id}/schedules/${sc.id}');
      reload();
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _deleteTech(BuildContext context, Technician t) async {
    final ok = await confirmDialog(context, title: 'Hapus teknisi?', message: '${t.name} akan dihapus.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/technicians/${t.id}');
      Bus.bump();
      if (context.mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (context.mounted) toast(context, 'Tidak dapat dihapus: teknisi masih punya data service.', error: true);
      debugPrint(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<Technician>(
      fullScreen: true,
      loader: () => Api.I.one('/technicians/$id', Technician.fromJson),
      builder: (context, t, reload) => Scaffold(
        appBar: AppBar(
          title: const Text('Detail Teknisi'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                if (await editTechnician(context, t)) reload();
              },
            ),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: C.danger), onPressed: () => _deleteTech(context, t)),
          ],
        ),
        body: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            AppCard(
              child: Row(
                children: [
                  Avatar(t.name, size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        Text(t.skill ?? 'Mekanik', style: TextStyle(color: C.mutedOf(context))),
                        const SizedBox(height: 6),
                        StatusChip(t.status),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${t.services.length}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.brandOf(context))),
                      Text('service', style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            SectionTitle('Jadwal (${t.schedules.length})', action: '+ Tambah', onAction: () => _schedule(context, t, null, reload)),
            if (t.schedules.isEmpty)
              AppCard(child: Center(child: Text('Belum ada jadwal', style: TextStyle(color: C.mutedOf(context)))))
            else
              for (final sc in t.schedules)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  child: Row(
                    children: [
                      const IconTile(Icons.event_rounded, size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fmtDate(sc.date), style: const TextStyle(fontWeight: FontWeight.w800)),
                            if (sc.note != null) Text(sc.note!, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => _schedule(context, t, sc, reload), icon: const Icon(Icons.edit_rounded, size: 19)),
                      IconButton(onPressed: () => _deleteSchedule(context, t, sc, reload), icon: const Icon(Icons.delete_outline_rounded, size: 19, color: C.danger)),
                    ],
                  ),
                ),
            SectionTitle('Riwayat Service (${t.services.length})'),
            if (t.services.isEmpty)
              AppCard(child: Center(child: Text('Belum ada service', style: TextStyle(color: C.mutedOf(context)))))
            else
              for (final s in t.services.take(30)) ServiceTile(service: s, onTap: () => go<dynamic>(context, ServiceDetailScreen(id: s.id))),
          ],
        ),
      ),
    );
  }
}
