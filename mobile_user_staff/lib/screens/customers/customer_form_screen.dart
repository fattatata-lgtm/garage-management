import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../widgets/common.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});
  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.customer?.name ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.customer?.phone ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.customer?.email ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.customer?.address ?? '');
  bool _busy = false;

  bool get _edit => widget.customer != null;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final body = {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
    };
    try {
      final d = _edit ? await Api.I.put('/customers/${widget.customer!.id}', body: body) : await Api.I.post('/customers', body: body);
      Bus.bump();
      if (mounted) Navigator.pop(context, Customer.fromJson(Map<String, dynamic>.from(d as Map)));
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
      appBar: AppBar(title: Text(_edit ? 'Edit Pelanggan' : 'Pelanggan Baru')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            LabeledField('Nama lengkap', TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: deco(null, hint: 'Contoh: Budi Santoso', icon: Icons.person_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            )),
            const SizedBox(height: 14),
            LabeledField('No. HP / WhatsApp', TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: deco(null, icon: Icons.phone_rounded, hint: '08123456789'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'No. HP wajib diisi';
                if (!RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(t)) return 'Format No. HP tidak valid';
                return null;
              },
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
            const SizedBox(height: 24),
            ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
