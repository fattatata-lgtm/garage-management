import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

const Map<String, String> _scopeLabel = {'SEMUA': 'Semua', 'SERVICE': 'Service', 'SPAREPART': 'Sparepart'};

/// Data Diskon (sama dengan Admin > Diskon di website).
/// ADMIN dan STAFF dapat menambah & mengubah diskon; menghapus hanya ADMIN.
class DiscountListScreen extends StatefulWidget {
  const DiscountListScreen({super.key});

  @override
  State<DiscountListScreen> createState() => _DiscountListScreenState();
}

class _DiscountListScreenState extends State<DiscountListScreen> {
  String _q = '';

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  Future<void> _delete(Discount d) async {
    final ok = await confirmDialog(context, title: 'Hapus diskon?', message: 'Hapus diskon ${d.name}?', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    try {
      await Api.I.delete('/discounts/${d.id}');
      Bus.bump();
      if (mounted) toast(context, 'Diskon dihapus');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message.isEmpty ? 'Gagal menghapus (diskon mungkin sudah dipakai transaksi).' : e.message, error: true);
    }
  }

  Widget _tile(Discount d, bool canEdit, bool canDelete) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(14, 12, canDelete ? 4 : 14, 12),
      onTap: canEdit ? () => _open(DiscountFormScreen(discount: d)) : null,
      child: Row(
        children: [
          const IconTile(Icons.percent_rounded, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.textOf(context))),
                const SizedBox(height: 3),
                Text(
                  [if (d.code != null) 'Kode ${d.code}', 'Berlaku: ${_scopeLabel[d.scope] ?? d.scope}'].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: C.mutedOf(context), fontSize: 12.5),
                ),
                const SizedBox(height: 6),
                StatusChip(d.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(d.type == 'PERCENTAGE' ? d.valueLabel : rp(d.value), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: C.brandOf(context))),
          if (canDelete)
            IconButton(
              tooltip: 'Hapus diskon',
              onPressed: () => _delete(d),
              icon: const Icon(Icons.delete_outline_rounded, size: 21, color: C.danger),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role;
    final canEdit = role == 'ADMIN' || role == 'STAFF';
    final canDelete = role == 'ADMIN';
    return Scaffold(
      appBar: AppBar(title: const Text('Data Diskon')),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(heroTag: null, 
              onPressed: () => _open(const DiscountFormScreen()),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Diskon'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(hint: 'Cari nama / kode diskon...', onChanged: (v) => setState(() => _q = v)),
          ),
          if (!canEdit)
            Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, size: 16, color: C.mutedOf(context)),
                SizedBox(width: 6),
                Expanded(child: Text('Anda tidak memiliki akses untuk mengubah diskon.', style: TextStyle(color: C.mutedOf(context), fontSize: 12))),
              ]),
            ),
          Expanded(
            child: AsyncBody<List<Discount>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/discounts', Discount.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((d) => q.isEmpty || d.name.toLowerCase().contains(q) || (d.code?.toLowerCase().contains(q) ?? false)).toList();
                if (list.isEmpty) {
                  return emptyList(
                    Icons.sell_outlined,
                    all.isEmpty ? 'Belum ada diskon' : 'Diskon tidak ditemukan',
                    all.isEmpty && canEdit ? 'Tekan tombol + Diskon untuk menambah promo.' : null,
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _tile(list[i], canEdit, canDelete),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tambah / edit diskon (Administrator & Staff).
class DiscountFormScreen extends StatefulWidget {
  const DiscountFormScreen({super.key, this.discount});
  final Discount? discount;

  @override
  State<DiscountFormScreen> createState() => _DiscountFormScreenState();
}

class _DiscountFormScreenState extends State<DiscountFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.discount?.name ?? '');
  late final TextEditingController _code = TextEditingController(text: widget.discount?.code ?? '');
  late final TextEditingController _value = TextEditingController(
    text: widget.discount == null ? '' : widget.discount!.value.toStringAsFixed(widget.discount!.value % 1 == 0 ? 0 : 2),
  );
  late String _type = widget.discount?.type ?? 'PERCENTAGE';
  late String _scope = widget.discount?.scope ?? 'SEMUA';
  late String _status = widget.discount?.status ?? 'AKTIF';
  bool _busy = false;

  bool get _edit => widget.discount != null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'code': _code.text.trim().toUpperCase(),
      'type': _type,
      'value': num.parse(_value.text.trim().replaceAll(',', '.')),
      'scope': _scope,
      'status': _status,
    };
    try {
      if (_edit) {
        await Api.I.put('/discounts/${widget.discount!.id}', body: body);
      } else {
        await Api.I.post('/discounts', body: body);
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

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
      );

  Widget _chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) => setState(onTap),
        selectedColor: C.soft(context, C.brand50),
        labelStyle: TextStyle(color: sel ? C.brandOf(context) : C.textOf(context), fontWeight: sel ? FontWeight.w800 : FontWeight.w600),
        side: BorderSide(color: sel ? C.brandOf(context) : C.lineOf(context)),
      );

  @override
  Widget build(BuildContext context) {
    final pct = _type == 'PERCENTAGE';
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Diskon' : 'Tambah Diskon')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LabeledField('Nama diskon', TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: deco(null, hint: 'Contoh: Diskon Member', icon: Icons.sell_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama diskon wajib diisi' : null,
            )),
            const SizedBox(height: 14),
            LabeledField('Kode kupon (opsional)', TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: deco(null, icon: Icons.qr_code_rounded, hint: 'MEMBER5'),
            )),
            const SizedBox(height: 18),
            _label('Tipe Diskon'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Persentase (%)', pct, () => _type = 'PERCENTAGE'),
              _chip('Nominal (Rp)', !pct, () => _type = 'NOMINAL'),
            ]),
            const SizedBox(height: 14),
            LabeledField('Nilai diskon', TextFormField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: deco(null, icon: pct ? Icons.percent_rounded : Icons.payments_rounded, hint: pct ? 'Mis. 10' : 'Mis. 20000'),
              validator: (v) {
                final n = num.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null) return 'Nilai diskon wajib diisi';
                if (n < 0) return 'Nilai tidak boleh negatif';
                if (pct && n > 100) return 'Persentase maksimal 100';
                return null;
              },
            )),
            const SizedBox(height: 18),
            _label('Berlaku Untuk'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in _scopeLabel.entries) _chip(e.value, _scope == e.key, () => _scope = e.key),
            ]),
            const SizedBox(height: 18),
            _label('Status'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Aktif', _status == 'AKTIF', () => _status = 'AKTIF'),
              _chip('Nonaktif', _status == 'NONAKTIF', () => _status = 'NONAKTIF'),
            ]),
            const SizedBox(height: 24),
            ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
