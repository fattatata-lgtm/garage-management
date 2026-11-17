import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_provider.dart';
import '../core/settings_provider.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController(text: Store.lastUsername);
  final _pass = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SettingsProvider>().load(authed: false);
    });
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await auth.login(_user.text.trim(), _pass.text);
    if (err == null) {
      settings.load(authed: true);
      return; // root otomatis pindah ke halaman utama
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  void _demo() {
    final auth = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    auth.demoLogin();
    settings.load(authed: true);
  }

  Future<void> _openServerSheet() async {
    final settings = context.read<SettingsProvider>();
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ServerSheet(),
    );
    if (changed == true) settings.load(authed: false);
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: C.isDark(context) ? const Color(0xFF0F1830) : C.brand800,
      body: Container(
        decoration: BoxDecoration(gradient: C.heroOf(context)),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                          child: TextButton.icon(
                            onPressed: _openServerSheet,
                            icon: const Icon(Icons.dns_rounded, size: 18, color: Colors.white70),
                            label: const Text('Server', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FadeSlideIn(
                          delay: Duration.zero,
                          offset: 20,
                          duration: const Duration(milliseconds: 650),
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: C.isDark(context) ? D.surface2 : Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 14))],
                              ),
                              child: st.logo.isNotEmpty
                                  ? Image.network(st.logo,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(Icons.build_rounded, size: 42, color: C.brandOf(context)))
                                  : Icon(Icons.build_rounded, size: 42, color: C.brandOf(context)),
                            ),
                            const SizedBox(height: 18),
                            Text(st.businessName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            const Text('Aplikasi Staff Bengkel', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 28),
                          ],
                        ),
                        ),
                      ),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        offset: 40,
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + MediaQuery.of(context).padding.bottom),
                        decoration: BoxDecoration(
                          color: C.bgOf(context),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Masuk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.textOf(context))),
                              const SizedBox(height: 4),
                              Text('Gunakan akun Staff Anda', style: TextStyle(color: C.mutedOf(context))),
                              const SizedBox(height: 20),
                              LabeledField('Username atau Email', TextFormField(
                                controller: _user,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: deco(null, hint: 'Masukkan username atau email', icon: Icons.person_rounded),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                              )),
                              const SizedBox(height: 14),
                              LabeledField('Password', TextFormField(
                                controller: _pass,
                                obscureText: !_show,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: deco(null, hint: 'Masukkan password', icon: Icons.lock_rounded,
                                    suffix: IconButton(
                                      icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                                      onPressed: () => setState(() => _show = !_show),
                                    )),
                                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                              )),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: C.soft(context, C.dangerBg), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: C.tone(context, C.danger), size: 19),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_error!, style: TextStyle(color: C.tone(context, C.danger), fontWeight: FontWeight.w600, fontSize: 13))),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              ActionButton(label: 'Masuk', icon: Icons.login_rounded, busy: _busy, onPressed: _submit),
                              const SizedBox(height: 10),
                              ActionButton(label: 'Coba Mode Demo (tanpa server)', icon: Icons.play_circle_outline_rounded, kind: BtnKind.tonal, onPressed: _busy ? null : _demo),
                              const SizedBox(height: 12),
                              Center(
                                child: Text('Server: ${Store.serverUrl}',
                                    style: TextStyle(color: C.mutedOf(context), fontSize: 11.5), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet pengaturan alamat server (penting di HP: isi dengan IP komputer server).
class ServerSheet extends StatefulWidget {
  const ServerSheet({super.key});

  @override
  State<ServerSheet> createState() => _ServerSheetState();
}

class _ServerSheetState extends State<ServerSheet> {
  final _ctrl = TextEditingController(text: Store.serverUrl);
  bool _testing = false;
  String? _result;
  bool _ok = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final err = await Api.ping(_ctrl.text);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _ok = err == null;
      _result = err ?? 'Terhubung ke server dengan baik.';
    });
  }

  Future<void> _save() async {
    await Store.setServerUrl(_ctrl.text);
    Api.I.configure();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: C.lineOf(context), borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          const Text('Alamat Server', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            'Isi dengan alamat komputer yang menjalankan backend, mis. 192.168.1.10:4000. HP dan komputer harus satu jaringan WiFi.',
            style: TextStyle(color: C.mutedOf(context), height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LabeledField('Alamat server', TextField(
            controller: _ctrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: deco(null, icon: Icons.dns_rounded, hint: '192.168.1.10:4000'),
          )),
          if (_result != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_ok ? Icons.check_circle_rounded : Icons.error_rounded, size: 18, color: _ok ? C.ok : C.danger),
                const SizedBox(width: 8),
                Expanded(child: Text(_result!, style: TextStyle(color: _ok ? C.ok : C.danger, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: ActionButton(label: 'Tes Koneksi', kind: BtnKind.secondary, busy: _testing, onPressed: _test)),
              const SizedBox(width: 12),
              Expanded(child: ActionButton(label: 'Simpan', onPressed: _save)),
            ],
          ),
        ],
      ),
    );
  }
}
