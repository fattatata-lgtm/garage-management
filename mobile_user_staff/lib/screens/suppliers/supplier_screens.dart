import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// Data Supplier sparepart (sama dengan menu Supplier di website).
class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String _q = '';

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  Future<void> _delete(Supplier s) async {
    final used = s.sparepartCount;
    final msg = used > 0
        ? 'Hapus supplier ${s.name}? $used sparepart yang memakai supplier ini akan menjadi tanpa supplier.'
        : 'Hapus supplier ${s.name}?';
    final ok = await confirmDialog(context, title: 'Hapus supplier?', message: msg, okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/suppliers/${s.id}');
      Bus.bump();
      if (mounted) toast(context, 'Supplier dihapus');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  bool _match(Supplier s, String q) =>
      q.isEmpty ||
      s.name.toLowerCase().contains(q) ||
      (s.contactPerson?.toLowerCase().contains(q) ?? false) ||
      (s.phone?.toLowerCase().contains(q) ?? false);

  Widget _tile(Supplier s) {
    final contact = [s.contactPerson, s.phone].whereType<String>().join(' · ');
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      onTap: () => _open(SupplierFormScreen(supplier: s)),
      child: Row(
        children: [
          const IconTile(Icons.local_shipping_rounded, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.textOf(context))),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(contact, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                ],
                if (s.address != null) ...[
                  const SizedBox(height: 2),
                  Text(s.address!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: C.soft(context, C.brand50), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.settings_rounded, size: 13, color: C.brandOf(context)),
                    const SizedBox(width: 4),
                    Text('${s.sparepartCount} sparepart', style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800, fontSize: 11.5)),
                  ]),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus supplier',
            onPressed: () => _delete(s),
            icon: const Icon(Icons.delete_outline_rounded, size: 21, color: C.danger),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Sparepart')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const SupplierFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Supplier'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(hint: 'Cari nama / kontak / telepon...', onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: AsyncBody<List<Supplier>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/suppliers', Supplier.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((s) => _match(s, q)).toList();
                if (list.isEmpty) {
                  return emptyList(
                    Icons.local_shipping_outlined,
                    all.isEmpty ? 'Belum ada supplier' : 'Supplier tidak ditemukan',
                    all.isEmpty ? 'Tekan tombol + Supplier untuk menambah pemasok sparepart.' : 'Ubah kata kunci pencarian.',
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _tile(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tambah / edit supplier.
class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key, this.supplier});
  final Supplier? supplier;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.supplier?.name ?? '');
  late final TextEditingController _contact = TextEditingController(text: widget.supplier?.contactPerson ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.supplier?.phone ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.supplier?.email ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.supplier?.address ?? '');
  late final TextEditingController _note = TextEditingController(text: widget.supplier?.note ?? '');
  bool _busy = false;

  bool get _edit => widget.supplier != null;

  @override
  void dispose() {
    for (final c in [_name, _contact, _phone, _email, _address, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    // Kolom kosong dikirim sebagai '' -> server menyimpannya sebagai kosong (sama seperti website).
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'contactPerson': _contact.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'address': _address.text.trim(),
      'note': _note.text.trim(),
    };
    try {
      if (_edit) {
        await Api.I.put('/suppliers/${widget.supplier!.id}', body: body);
      } else {
        await Api.I.post('/suppliers', body: body);
      }
      Bus.bump();
      if (mounted) Navigator.pop(context, true);
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
      appBar: AppBar(title: Text(_edit ? 'Edit Supplier' : 'Supplier Baru')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LabeledField('Nama supplier', TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: deco(null, hint: 'Contoh: PT Sumber Makmur', icon: Icons.local_shipping_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama supplier wajib diisi' : null,
            )),
            const SizedBox(height: 14),
            LabeledField('Kontak person (opsional)', TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: deco(null, hint: 'Contoh: Pak Hendra', icon: Icons.person_rounded),
            )),
            const SizedBox(height: 14),
            LabeledField('Telepon (opsional)', TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: deco(null, icon: Icons.phone_rounded, hint: '08xxxxxxxxxx'),
            )),
            const SizedBox(height: 14),
            LabeledField('Email (opsional)', TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: deco(null, hint: 'Contoh: nama@email.com', icon: Icons.mail_rounded),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isNotEmpty && !RegExp(r'^\S+@\S+\.\S+$').hasMatch(t)) return 'Format email tidak valid';
                return null;
              },
            )),
            const SizedBox(height: 14),
            LabeledField('Alamat (opsional)', TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco(null, hint: 'Contoh: Jl. Merdeka No. 10, Malang', icon: Icons.location_on_rounded),
            )),
            const SizedBox(height: 14),
            LabeledField('Catatan (opsional)', TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco(null, icon: Icons.notes_rounded, hint: 'Mis. syarat pembayaran, jadwal kirim'),
            )),
            const SizedBox(height: 24),
            ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
