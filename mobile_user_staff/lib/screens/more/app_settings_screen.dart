import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/nav.dart';
import '../../core/settings_provider.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'printer_settings_screen.dart';

const int _logoMaxBytes = 2 * 1024 * 1024; // 2 MB, sama dengan batas di server

/// Pengaturan Aplikasi: logo, nama, alamat, telepon, pajak, dan ukuran kertas struk.
/// Sama dengan Admin > Pengaturan Aplikasi di website; berlaku untuk seluruh bengkel.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _taxService = TextEditingController();
  final _taxSales = TextEditingController();

  String? _logoUrl;
  Map<String, dynamic>? _saved; // nilai terakhir dari server, untuk tombol Reset

  bool _loading = true;
  bool _saving = false;
  bool _logoBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _taxService.dispose();
    _taxSales.dispose();
    super.dispose();
  }

  String _numText(dynamic v, num fallback) {
    final n = num.tryParse('$v') ?? fallback;
    return n % 1 == 0 ? n.toInt().toString() : n.toString();
  }

  void _apply(Map<String, dynamic> d) {
    _saved = d;
    _name.text = (d['businessName'] as String?) ?? '';
    _address.text = (d['address'] as String?) ?? '';
    _phone.text = (d['phone'] as String?) ?? '';
    _taxService.text = _numText(d['taxService'], 10);
    _taxSales.text = _numText(d['taxSales'], 10);
    _logoUrl = d['logoUrl'] as String?;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await Api.I.get('/settings');
      if (!mounted) return;
      setState(() {
        _apply(Map<String, dynamic>.from(d as Map));
        _loading = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _refreshGlobal() => context.read<SettingsProvider>().load(authed: true);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final d = await Api.I.put('/settings', body: {
        'businessName': _name.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.trim(),
        'taxService': num.parse(_taxService.text.trim().replaceAll(',', '.')),
        'taxSales': num.parse(_taxSales.text.trim().replaceAll(',', '.')),
      });
      if (d is Map) _saved = Map<String, dynamic>.from(d);
      await _refreshGlobal();
      if (mounted) toast(context, 'Pengaturan berhasil disimpan.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message.isEmpty ? 'Gagal menyimpan pengaturan.' : e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLogo() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1400, imageQuality: 90);
    } catch (_) {
      if (mounted) toast(context, 'Tidak dapat membuka galeri.', error: true);
      return;
    }
    if (file == null) return;
    if (await file.length() > _logoMaxBytes) {
      if (mounted) toast(context, 'Ukuran logo maksimal 2 MB.', error: true);
      return;
    }
    setState(() => _logoBusy = true);
    try {
      final d = await Api.I.uploadImage('/settings/logo', field: 'logo', filePath: file.path, fileName: file.name, mime: file.mimeType);
      if (d is Map && mounted) setState(() => _logoUrl = d['logoUrl'] as String?);
      await _refreshGlobal();
      if (mounted) toast(context, 'Logo berhasil diunggah.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message.isEmpty ? 'Gagal mengunggah logo.' : e.message, error: true);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _removeLogo() async {
    final ok = await confirmDialog(context, title: 'Hapus logo?', message: 'Logo bengkel akan dihapus dari aplikasi, login, dan struk.', okLabel: 'Hapus', danger: true);
    if (!ok) return;
    setState(() => _logoBusy = true);
    try {
      await Api.I.delete('/settings/logo');
      if (mounted) setState(() => _logoUrl = null);
      await _refreshGlobal();
      if (mounted) toast(context, 'Logo dihapus.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message.isEmpty ? 'Gagal menghapus logo.' : e.message, error: true);
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  // ------------------------------------------------------------------ Komponen UI

  /// Kartu bagian: judul berada DI DALAM kartu (bukan memotong garis kolom).
  Widget _section(IconData icon, String title, List<Widget> children, {Color? color, Color? bg}) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon, color: color ?? C.brand, bg: bg ?? C.brand50, size: 34),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.textOf(context)))),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  /// Kolom isian dengan label DI ATAS kolom (tanpa label melayang yang memotong garis).
  Widget _field(
    String label,
    TextEditingController c, {
    IconData? icon,
    String? hint,
    TextInputType? type,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.mutedOf(context))),
        ),
        TextFormField(
          controller: c,
          keyboardType: type,
          inputFormatters: formatters,
          validator: validator,
          minLines: 1,
          maxLines: maxLines,
          textCapitalization: caps,
          decoration: deco(null, icon: icon, hint: hint),
        ),
      ],
    );
  }

  String? _taxValidator(String? v) {
    final n = num.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Wajib diisi';
    if (n < 0 || n > 100) return 'Isi 0 - 100';
    return null;
  }

  Widget _logoBox() {
    final hasLogo = _logoUrl != null && _logoUrl!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 112,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.soft(context, C.slateBg),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.lineOf(context)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: hasLogo
                ? Image.network(
                    Store.asset(_logoUrl),
                    key: ValueKey(_logoUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, size: 34, color: C.mutedOf(context)),
                  )
                : Column(
                    key: const ValueKey('empty'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_outlined, size: 34, color: C.mutedOf(context)),
                      const SizedBox(height: 6),
                      Text('Belum ada logo', style: TextStyle(color: C.mutedOf(context), fontSize: 12.5)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ActionButton(
                label: hasLogo ? 'Ganti Logo' : 'Unggah Logo',
                icon: Icons.upload_rounded,
                kind: BtnKind.tonal,
                busy: _logoBusy,
                onPressed: _logoBusy ? null : _pickLogo,
              ),
            ),
            if (hasLogo) ...[
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: 'Hapus',
                  icon: Icons.delete_outline_rounded,
                  kind: BtnKind.secondary,
                  onPressed: _logoBusy ? null : _removeLogo,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'PNG, JPG, WEBP, atau GIF, maksimal 2 MB. Logo tampil di Beranda, halaman login, dan struk.',
          style: TextStyle(color: C.mutedOf(context), fontSize: 12, height: 1.35),
        ),
      ],
    );
  }

  Widget _darkModeRow(SettingsProvider st) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: Tween<double>(begin: 0.75, end: 1).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
          ),
          child: KeyedSubtree(
            key: ValueKey(st.isDarkMode),
            child: IconTile(
              st.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: st.isDarkMode ? Colors.amber : C.brand,
              bg: st.isDarkMode ? C.warnBg : C.brand50,
              size: 42,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mode Malam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.textOf(context))),
              const SizedBox(height: 2),
              Text(st.isDarkMode ? 'Tema gelap aktif' : 'Tema terang aktif', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
            ],
          ),
        ),
        Switch(value: st.isDarkMode, onChanged: (v) => st.toggleDarkMode(v)),
      ],
    );
  }

  Widget _printerRow() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => go<dynamic>(context, const PrinterSettingsScreen()),
      child: Row(
        children: [
          const IconTile(Icons.print_rounded, color: C.ok, bg: C.okBg, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: C.textOf(context))),
                const SizedBox(height: 2),
                Text('Bluetooth, jaringan, server, PDF', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: C.mutedOf(context)),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: C.cardOf(context),
        border: Border(top: BorderSide(color: C.lineOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: ActionButton(
                  label: 'Reset',
                  icon: Icons.undo_rounded,
                  kind: BtnKind.secondary,
                  onPressed: _saving
                      ? null
                      : () {
                          if (_saved != null) setState(() => _apply(_saved!));
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ActionButton(label: 'Simpan', icon: Icons.check_rounded, busy: _saving, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Pengaturan Aplikasi')), body: const SkeletonList(count: 4));
    }
    if (_error != null) {
      return Scaffold(appBar: AppBar(title: const Text('Pengaturan Aplikasi')), body: ErrorView(message: _error!, onRetry: _load));
    }
    final st = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Aplikasi')),
      bottomNavigationBar: _bottomBar(),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _section(Icons.image_rounded, 'Logo Bengkel', [_logoBox()]),
            _section(Icons.storefront_rounded, 'Identitas Bengkel', [
              _field('Nama bengkel', _name,
                  icon: Icons.storefront_rounded,
                  hint: 'Mis. Self Automotive',
                  caps: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama bengkel tidak boleh kosong' : null),
              const SizedBox(height: 14),
              _field('Alamat', _address, icon: Icons.place_rounded, hint: 'Alamat lengkap bengkel', maxLines: 3, caps: TextCapitalization.sentences),
              const SizedBox(height: 14),
              _field('No. telepon', _phone, icon: Icons.call_rounded, hint: 'Mis. 021-1234567', type: TextInputType.phone),
            ]),
            _section(Icons.receipt_long_rounded, 'Pajak', [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field('Tax service (%)', _taxService,
                        icon: Icons.percent_rounded,
                        type: const TextInputType.numberWithOptions(decimal: true),
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        validator: _taxValidator),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('Tax sales (%)', _taxSales,
                        icon: Icons.percent_rounded,
                        type: const TextInputType.numberWithOptions(decimal: true),
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        validator: _taxValidator),
                  ),
                ],
              ),
            ]),
            _section(Icons.phone_android_rounded, 'Tampilan & Perangkat', [
              _darkModeRow(st),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: C.lineOf(context)),
              ),
              _printerRow(),
            ]),
          ],
        ),
      ),
    );
  }
}
