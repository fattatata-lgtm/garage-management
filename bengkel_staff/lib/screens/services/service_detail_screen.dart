import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/launchers.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../core/settings_provider.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/picker.dart';
import '../../print/pdf_docs.dart';
import '../../print/printer.dart';
import '../../print/receipts.dart';
import 'service_form_screen.dart';

class _JasaRow {
  _JasaRow(String n, num c)
      : name = TextEditingController(text: n),
        cost = TextEditingController(text: rpText(c));
  final TextEditingController name;
  final TextEditingController cost;
  num get costValue => parseRp(cost.text);
  void dispose() {
    name.dispose();
    cost.dispose();
  }
}

class _PartRow {
  _PartRow({required this.sparepartId, required this.name, required this.code, required this.qty, required this.price});
  final int sparepartId;
  final String name;
  final String code;
  int qty;
  final num price;
}

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key, required this.id});
  final int id;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  Service? _s;
  String? _loadError;
  bool _busy = false;

  List<ServiceType> _types = [];
  List<Sparepart> _stock = [];
  List<Discount> _discounts = [];
  bool _refsLoaded = false;

  final _km = TextEditingController();
  final _rec = TextEditingController();
  final _note = TextEditingController();
  final _paid = TextEditingController();
  DateTime? _nextDate;
  int? _discountId;
  final List<_JasaRow> _jasa = [];
  final List<_PartRow> _used = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _km.dispose();
    _rec.dispose();
    _note.dispose();
    _paid.dispose();
    for (final r in _jasa) {
      r.dispose();
    }
    super.dispose();
  }

  num get _taxRate => context.read<SettingsProvider>().taxService;

  // ------------------------------------------------------------------ Muat data

  Future<void> _load() async {
    try {
      final s = await Api.I.one('/services/${widget.id}', Service.fromJson);
      if (!mounted) return;
      setState(() {
        _hydrate(s);
        _loadError = null;
      });
      if (!_refsLoaded && (s.status == 'DIKERJAKAN' || s.status == 'MENUNGGU_PEMBAYARAN')) _loadRefs();
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  void _hydrate(Service s) {
    _s = s;
    _km.text = s.km == null ? '' : num0(s.km);
    _rec.text = s.nextRecommendation;
    _note.text = s.internalNote;
    _nextDate = s.nextDate;
    _discountId = s.discountId;
    for (final r in _jasa) {
      r.dispose();
    }
    _jasa
      ..clear()
      ..addAll(s.details.map((d) => _JasaRow(d.name, d.cost)));
    _used
      ..clear()
      ..addAll(s.parts.map((p) => _PartRow(sparepartId: p.sparepartId, name: p.name, code: p.code, qty: p.qty, price: p.price)));
  }

  Future<T> _safe<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _loadRefs() async {
    _refsLoaded = true;
    final r = await Future.wait<dynamic>([
      _safe(() => Api.I.list('/service-types', ServiceType.fromJson), <ServiceType>[]),
      _safe(() => Api.I.list('/spareparts', Sparepart.fromJson), <Sparepart>[]),
      _safe(() => Api.I.list('/discounts', Discount.fromJson, query: {'activeOnly': 'true'}), <Discount>[]),
    ]);
    if (!mounted) return;
    setState(() {
      _types = r[0] as List<ServiceType>;
      _stock = r[1] as List<Sparepart>;
      _discounts = (r[2] as List<Discount>).where((d) => d.scope == 'SEMUA' || d.scope == 'SERVICE').toList();
    });
  }

  Future<void> _refreshStock() async {
    final list = await _safe(() => Api.I.list('/spareparts', Sparepart.fromJson), <Sparepart>[]);
    if (mounted && list.isNotEmpty) setState(() => _stock = list);
  }

  void _apply(dynamic d) {
    final s = Service.fromJson(Map<String, dynamic>.from(d as Map));
    if (mounted) setState(() => _hydrate(s));
    Bus.bump();
    _refreshStock();
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------ Hitung

  ({num jasa, num parts, num subtotal, num disc, num tax, num total}) _calc() {
    final jasa = _jasa.fold<num>(0, (a, r) => a + r.costValue);
    final parts = _used.fold<num>(0, (a, r) => a + r.price * r.qty);
    final subtotal = jasa + parts;
    Discount? d;
    for (final x in _discounts) {
      if (x.id == _discountId) d = x;
    }
    num disc;
    if (d != null) {
      disc = d.amountFor(subtotal);
    } else if (_discountId != null && _discountId == _s?.discountId) {
      disc = _s!.discountAmount;
    } else {
      disc = 0;
    }
    num after = subtotal - disc;
    if (after < 0) after = 0;
    final tax = after * _taxRate / 100;
    return (jasa: jasa, parts: parts, subtotal: subtotal, disc: disc, tax: tax, total: after + tax);
  }

  int _availFor(int id) {
    final saved = _s!.parts.where((p) => p.sparepartId == id).toList();
    final orig = saved.fold<int>(0, (a, p) => a + p.qty);
    final inStock = _stock.where((e) => e.id == id).toList();
    if (inStock.isNotEmpty) return inStock.first.stock + orig;
    return saved.isNotEmpty ? saved.first.stock + orig : 0;
  }

  // ------------------------------------------------------------------ Aksi

  Future<void> _start() => _run(() async {
        final d = await Api.I.patch('/services/${widget.id}/start');
        _apply(d);
        if (!_refsLoaded) _loadRefs();
      });

  Future<void> _saveWork() async {
    final s = _s!;
    final km = _km.text.trim().isEmpty ? null : parseRp(_km.text);
    final payload = <String, dynamic>{
      'km': km,
      'details': _jasa
          .where((r) => r.name.text.trim().isNotEmpty)
          .map((r) => {'name': r.name.text.trim(), 'description': null, 'cost': r.costValue})
          .toList(),
      'spareparts': _used.map((r) => {'sparepartId': r.sparepartId, 'qty': r.qty, 'price': r.price}).toList(),
      'nextServiceRecommendation': _rec.text.trim(),
      'nextServiceDate': _nextDate == null ? null : toApiNoon(_nextDate!),
      'internalNote': _note.text.trim(),
    };
    if (s.status == 'MENUNGGU_PEMBAYARAN') payload['discountId'] = _discountId;
    final d = await Api.I.put('/services/${s.id}/work', body: payload);
    _apply(d);
  }

  Future<void> _onSave() => _run(() async {
        await _saveWork();
        if (mounted) toast(context, _s!.status == 'DIKERJAKAN' ? 'Pekerjaan disimpan' : 'Tagihan diperbarui');
      });

  Future<void> _onFinish() async {
    if (_km.text.trim().isEmpty) {
      toast(context, 'Kilometer kendaraan wajib diisi.', error: true);
      return;
    }
    if (_jasa.where((r) => r.name.text.trim().isNotEmpty).isEmpty) {
      toast(context, 'Tambahkan minimal 1 jasa pekerjaan.', error: true);
      return;
    }
    final ok = await confirmDialog(context,
        title: 'Selesai dikerjakan?',
        message: 'Pekerjaan akan disimpan dan tagihan siap dibayar di kasir.',
        okLabel: 'Ya, Selesai');
    if (!ok) return;
    await _run(() async {
      await _saveWork();
      final d = await Api.I.patch('/services/${widget.id}/finish-work');
      _apply(d);
    });
  }

  Future<void> _onPay() async {
    final paid = parseRp(_paid.text);
    final preview = _calc();
    if (paid <= 0 || paid < preview.total) {
      toast(context, 'Jumlah dibayar tidak boleh kurang dari total ${rp(preview.total)}.', error: true);
      return;
    }
    final ok = await confirmDialog(context,
        title: 'Terima pembayaran?',
        message: 'Total ${rp(preview.total)}, dibayar ${rp(paid)}, kembalian ${rp(paid - preview.total)}.',
        okLabel: 'Bayar & Selesai');
    if (!ok) return;
    await _run(() async {
      await _saveWork();
      final d = await Api.I.post('/services/${widget.id}/complete', body: {'paid': paid});
      _apply(d);
      if (mounted) toast(context, 'Pembayaran diterima. Service lunas ✅');
    });
  }

  Future<void> _onWhatsApp() => _run(() async {
        final d = await Api.I.get('/services/${widget.id}/whatsapp-message');
        final m = Map<String, dynamic>.from(d as Map);
        final ok = await openWhatsApp(m['phone'] as String?, (m['message'] as String?) ?? '');
        if (!ok && mounted) toast(context, 'Tidak dapat membuka WhatsApp atau nomor pelanggan kosong.', error: true);
      });

  // ---------- Cetak (sama dengan web: Bukti Diterima, Tagihan, Invoice, Struk, Work Order)

  Future<void> _printReceived() {
    final svc = _s!;
    return PrintService.thermal(context, context.read<SettingsProvider>(), (shop) => buildReceivedReceipt(svc, shop), title: 'Bukti Service Diterima');
  }

  Future<void> _printWorkOrder() {
    final svc = _s!;
    return PrintService.thermal(context, context.read<SettingsProvider>(), (shop) => buildWorkOrderReceipt(svc, shop), title: 'Work Order');
  }

  /// mode: 'tagihan' (belum dibayar) | 'invoice' | 'thermal' (struk lunas)
  Future<void> _printBilling(String mode) async {
    final st = context.read<SettingsProvider>();
    var svc = _s!;
    if (mode == 'tagihan' && svc.status == 'MENUNGGU_PEMBAYARAN') {
      var ok = true;
      await _run(() async {
        try {
          await _saveWork(); // pastikan rincian terbaru tersimpan sebelum dicetak
        } catch (_) {
          ok = false;
          rethrow;
        }
      });
      if (!ok || !mounted) return;
      svc = _s!;
    }
    final tagihan = mode == 'tagihan';
    final thermalBill = tagihan && PrintService.isRaw(st);
    if (mode != 'thermal' && !thermalBill) {
      await PrintService.invoice(context, st, serviceInvoiceData(svc, tagihan: tagihan));
      return;
    }
    await PrintService.thermal(context, st, (shop) => buildServiceReceipt(svc, shop, billing: tagihan), title: tagihan ? 'Tagihan Service' : 'Struk Service');
  }

  Future<void> _onDelete() async {
    final ok = await confirmDialog(context,
        title: 'Hapus transaksi?',
        message: 'Transaksi ${_s!.invoiceNo} akan dihapus dan stok sparepart yang terpakai dikembalikan. Tindakan ini tidak dapat dibatalkan.',
        okLabel: 'Hapus',
        danger: true);
    if (!ok) return;
    await _run(() async {
      await Api.I.delete('/services/${widget.id}');
      Bus.bump();
      if (mounted) Navigator.pop(context, true);
    });
  }

  Future<void> _onEdit() async {
    final res = await go<Service>(context, ServiceFormScreen(service: _s));
    if (res != null) _load();
  }

  // ------------------------------------------------------------------ Tambah item

  Future<void> _addType() async {
    if (_types.isEmpty) {
      toast(context, 'Daftar jenis layanan belum tersedia. Gunakan "Jasa Manual".', error: true);
      return;
    }
    final t = await showPickerSheet<ServiceType>(
      context,
      title: 'Pilih Jenis Layanan',
      items: _types,
      matches: (t, q) => t.name.toLowerCase().contains(q) || (t.description?.toLowerCase().contains(q) ?? false),
      itemBuilder: (context, t) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (t.description != null) Text(t.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
              ],
            ),
          ),
          Text(rp(t.estimatedCost), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (t != null) setState(() => _jasa.add(_JasaRow(t.name, t.estimatedCost)));
  }

  Future<void> _addPart() async {
    if (_stock.isEmpty) {
      toast(context, 'Data sparepart belum tersedia. Tarik layar untuk memuat ulang.', error: true);
      return;
    }
    final sp = await showPickerSheet<Sparepart>(
      context,
      title: 'Pilih Sparepart',
      searchHint: 'Cari nama / kode...',
      scannable: true,
      items: _stock,
      matches: (e, q) => e.name.toLowerCase().contains(q) || e.code.toLowerCase().contains(q),
      exactMatch: (e, code) => e.code.toLowerCase() == code.toLowerCase(),
      disabled: (e) => _availFor(e.id) <= 0,
      itemBuilder: (context, e) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${e.code} · stok ${_availFor(e.id)}', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
              ],
            ),
          ),
          Text(rp(e.sellPrice), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (sp == null) return;
    final existing = _used.where((r) => r.sparepartId == sp.id).toList();
    if (existing.isNotEmpty) {
      _changeQty(existing.first, 1);
    } else {
      setState(() => _used.add(_PartRow(sparepartId: sp.id, name: sp.name, code: sp.code, qty: 1, price: sp.sellPrice)));
    }
  }

  void _changeQty(_PartRow r, int delta) {
    final next = r.qty + delta;
    if (next < 1) return;
    if (next > _availFor(r.sparepartId)) {
      toast(context, 'Stok ${r.name} tidak mencukupi (tersedia ${_availFor(r.sparepartId)}).', error: true);
      return;
    }
    setState(() => r.qty = next);
  }

  Future<void> _pickDiscount() async {
    final none = Discount(id: -1, name: 'Tanpa diskon', type: 'NOMINAL', value: 0, scope: 'SEMUA', status: 'AKTIF');
    final res = await showPickerSheet<Discount>(
      context,
      title: 'Pilih Diskon / Kupon',
      items: _discounts,
      matches: (d, q) => d.name.toLowerCase().contains(q) || (d.code?.toLowerCase().contains(q) ?? false),
      header: Builder(
        builder: (context) => ListTile(
          leading: Icon(Icons.block_rounded, color: C.mutedOf(context)),
          title: const Text('Tanpa diskon', style: TextStyle(fontWeight: FontWeight.w700)),
          onTap: () => Navigator.pop(context, none),
        ),
      ),
      itemBuilder: (context, d) => Row(
        children: [
          const IconTile(Icons.local_offer_rounded, color: C.ok, bg: C.okBg, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (d.code != null) Text('Kode ${d.code}', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
              ],
            ),
          ),
          Text(d.type == 'PERCENTAGE' ? d.valueLabel : rp(d.value), style: const TextStyle(color: C.ok, fontWeight: FontWeight.w800)),
        ],
      ),
    );
    if (res != null) setState(() => _discountId = res.id == -1 ? null : res.id);
  }

  // ------------------------------------------------------------------ UI

  Widget _card({required String title, required IconData icon, required Widget child, Widget? action}) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: C.brandOf(context)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.textOf(context)))),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Service')),
        body: _loadError != null ? ErrorView(message: _loadError!, onRetry: _load) : const Center(child: CircularProgressIndicator()),
      );
    }
    final editable = s.status == 'DIKERJAKAN' || s.status == 'MENUNGGU_PEMBAYARAN';

    return Scaffold(
      appBar: AppBar(
        title: Text(s.invoiceNo),
        actions: [
          IconButton(tooltip: 'Kirim WhatsApp', icon: const Icon(Icons.chat_rounded), onPressed: _busy ? null : _onWhatsApp),
          if (!s.lunas)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) {
                if (v == 'edit') _onEdit();
                if (v == 'delete') _onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit data service')),
                PopupMenuItem(value: 'delete', child: Text('Hapus service', style: TextStyle(color: C.danger))),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.invoiceNo, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.textOf(context)))),
                      StatusChip(s.status),
                    ],
                  ),
                ],
              ),
            ),
            _vehicleCard(s),
            if (s.status == 'DITERIMA')
              _card(
                title: 'Service Diterima',
                icon: Icons.inbox_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kendaraan sudah tercatat masuk bengkel. Cetak bukti untuk pelanggan atau kirim kabar lewat WhatsApp, lalu mulai pengerjaan.',
                        style: TextStyle(color: C.mutedOf(context), height: 1.4, fontSize: 13)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: ActionButton(label: 'Kirim WA', icon: Icons.chat_rounded, kind: BtnKind.secondary, busy: _busy, onPressed: _onWhatsApp)),
                        const SizedBox(width: 10),
                        Expanded(child: ActionButton(label: 'Cetak Diterima', icon: Icons.print_rounded, kind: BtnKind.secondary, onPressed: _printReceived)),
                      ],
                    ),
                  ],
                ),
              ),
            if (editable) ..._editor(s) else if (s.lunas) ..._readonly(s),
            if (s.status == 'MENUNGGU_PEMBAYARAN') _paymentCard(s),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(s),
    );
  }

  Widget _vehicleCard(Service s) {
    final v = s.vehicle;
    final c = v?.customer;
    return _card(
      title: 'Kendaraan & Pemilik',
      icon: Icons.directions_car_rounded,
      child: Column(
        children: [
          Row(
            children: [
              IconTile(v?.isMotor == true ? Icons.two_wheeler_rounded : Icons.directions_car_rounded, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v?.modelLabel ?? '-', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: C.textOf(context))),
                    const SizedBox(height: 4),
                    PlateBadge(s.plate),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Avatar(c?.name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c?.name ?? '-', style: TextStyle(fontWeight: FontWeight.w800, color: C.textOf(context))),
                    Text(c?.phone ?? '-', style: TextStyle(color: C.mutedOf(context), fontSize: 13)),
                  ],
                ),
              ),
              if (c != null)
                IconButton.filledTonal(
                  onPressed: () => callPhone(c.phone),
                  icon: const Icon(Icons.phone_rounded, size: 20),
                ),
            ],
          ),
          const Divider(height: 24),
          if (v != null) ...[
            InfoRow('Warna', v.color ?? '-'),
            InfoRow('No. Rangka', v.vin ?? '-'),
            InfoRow('No. Mesin', v.engineNumber ?? '-'),
          ],
          InfoRow('Teknisi', s.technician?.name ?? '-'),
          InfoRow('Tanggal', fmtDate(s.date)),
          if (s.km != null) InfoRow('Kilometer', '${num0(s.km)} km'),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.soft(context, C.warnBg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KELUHAN', style: TextStyle(color: C.warn, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6)),
                const SizedBox(height: 4),
                Text(s.complaint.isEmpty ? '-' : s.complaint, style: TextStyle(color: C.textOf(context), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Editor pengerjaan / tagihan (status Dikerjakan & Menunggu Pembayaran)

  List<Widget> _editor(Service s) {
    final billing = s.status == 'MENUNGGU_PEMBAYARAN';
    final calc = _calc();
    return [
      if (!billing)
        _card(
          title: 'Kilometer Kendaraan',
          icon: Icons.speed_rounded,
          child: LabeledField('KM saat ini (wajib)', TextField(
            controller: _km,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            decoration: deco(null, icon: Icons.speed_rounded, hint: 'Contoh: 45.000'),
          )),
        ),
      _card(
        title: 'Jasa / Pekerjaan',
        icon: Icons.build_rounded,
        child: Column(
          children: [
            if (_jasa.isEmpty)
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belum ada jasa. Tambahkan di bawah.', style: TextStyle(color: C.mutedOf(context)))),
            for (var i = 0; i < _jasa.length; i++) _jasaRow(i),
            Row(
              children: [
                Expanded(child: ActionButton(label: 'Jenis Layanan', icon: Icons.list_alt_rounded, kind: BtnKind.tonal, onPressed: _addType)),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    label: 'Jasa Manual',
                    icon: Icons.add_rounded,
                    kind: BtnKind.secondary,
                    onPressed: () => setState(() => _jasa.add(_JasaRow('', 0))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      _card(
        title: 'Sparepart Dipakai',
        icon: Icons.settings_rounded,
        child: Column(
          children: [
            if (_used.isEmpty)
              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Belum ada sparepart dipakai.', style: TextStyle(color: C.mutedOf(context)))),
            for (var i = 0; i < _used.length; i++) _partRow(_used[i]),
            ActionButton(label: 'Tambah Sparepart (cari / scan)', icon: Icons.qr_code_scanner_rounded, kind: BtnKind.tonal, onPressed: _addPart),
          ],
        ),
      ),
      _card(
        title: 'Rekomendasi & Catatan',
        icon: Icons.notes_rounded,
        child: Column(
          children: [
            LabeledField('Rekomendasi service berikutnya', TextField(
              controller: _rec,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco(null, hint: 'Contoh: Ganti oli 5.000 km lagi', icon: Icons.tips_and_updates_rounded),
            )),
            const SizedBox(height: 12),
            FieldTile(
              label: 'Tanggal service berikutnya',
              icon: Icons.event_rounded,
              value: dateOrDash(_nextDate),
              trailing: _nextDate != null
                  ? GestureDetector(onTap: () => setState(() => _nextDate = null), child: const Icon(Icons.close_rounded, size: 20))
                  : const Icon(Icons.edit_calendar_rounded, size: 20),
              onTap: () async {
                final d = await pickDate(context, initial: _nextDate ?? DateTime.now().add(const Duration(days: 90)));
                if (d != null) setState(() => _nextDate = d);
              },
            ),
            const SizedBox(height: 12),
            LabeledField('Catatan internal (tidak dicetak / dikirim)', TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco(null, hint: 'Catatan untuk internal bengkel', icon: Icons.lock_outline_rounded),
            )),
          ],
        ),
      ),
      if (billing)
        _card(
          title: 'Diskon / Kupon',
          icon: Icons.local_offer_rounded,
          child: FieldTile(
            label: 'Diskon',
            showLabel: false,
            icon: Icons.confirmation_number_rounded,
            value: _discountId == null
                ? 'Tanpa diskon'
                : (_discounts.where((d) => d.id == _discountId).isNotEmpty
                    ? _discounts.firstWhere((d) => d.id == _discountId).name
                    : (s.discount?.name ?? 'Diskon')),
            onTap: _pickDiscount,
          ),
        ),
      _card(
        title: 'Ringkasan Biaya',
        icon: Icons.receipt_long_rounded,
        child: Column(
          children: [
            SummaryRow('Total jasa', rp(calc.jasa)),
            SummaryRow('Total sparepart', rp(calc.parts)),
            const Divider(height: 18),
            SummaryRow('Subtotal', rp(calc.subtotal)),
            SummaryRow('Diskon', '-${rp(calc.disc)}', color: C.ok),
            SummaryRow('Pajak (${_taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1)}%)', rp(calc.tax)),
            const Divider(height: 18),
            SummaryRow('Total', rp(calc.total), bold: true, big: true, color: C.brandOf(context)),
          ],
        ),
      ),
    ];
  }

  Widget _jasaRow(int i) {
    final r = _jasa[i];
    return Container(
      key: ObjectKey(r),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.bgOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LabeledField('Nama jasa', TextField(
                  controller: r.name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: deco(null, hint: 'Contoh: Ganti oli mesin'),
                )),
              ),
              IconButton(
                tooltip: 'Hapus',
                onPressed: () => setState(() {
                  _jasa.removeAt(i).dispose();
                }),
                icon: const Icon(Icons.delete_outline_rounded, color: C.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledField('Biaya', TextField(
            controller: r.cost,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: deco(null, hint: 'Contoh: 50000', prefixText: 'Rp '),
          )),
        ],
      ),
    );
  }

  Widget _partRow(_PartRow r) {
    return Container(
      key: ObjectKey(r),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: C.bgOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: C.textOf(context))),
                const SizedBox(height: 2),
                Text('${r.code} · ${rp(r.price)}', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                const SizedBox(height: 2),
                Text(rp(r.price * r.qty), style: TextStyle(color: C.brandOf(context), fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => _changeQty(r, -1), icon: const Icon(Icons.remove_circle_outline_rounded)),
          Text('${r.qty}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.textOf(context))),
          IconButton(visualDensity: VisualDensity.compact, onPressed: () => _changeQty(r, 1), icon: Icon(Icons.add_circle_outline_rounded, color: C.brandOf(context))),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _used.remove(r)),
            icon: const Icon(Icons.delete_outline_rounded, color: C.danger),
          ),
        ],
      ),
    );
  }

  // ---------- Pembayaran

  Widget _paymentCard(Service s) {
    final total = _calc().total;
    final paid = parseRp(_paid.text);
    final change = paid > total ? paid - total : 0;
    final pas = total.ceil();
    final quick = <int>{pas, (pas / 50000).ceil() * 50000, (pas / 100000).ceil() * 100000}.where((n) => n > 0).toList();

    return _card(
      title: 'Pembayaran',
      icon: Icons.payments_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionButton(
            label: 'Panggil ke Kasir',
            icon: Icons.campaign_rounded,
            kind: BtnKind.tonal,
            onPressed: () {
              speakCashierCall(s.plate, s.ownerName);
              toast(context, 'Memanggil ${s.ownerName} ke kasir...');
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: ActionButton(label: 'Cetak Tagihan', icon: Icons.print_rounded, kind: BtnKind.secondary, onPressed: () => _printBilling('tagihan'))),
              const SizedBox(width: 10),
              Expanded(child: ActionButton(label: 'Kirim WA', icon: Icons.chat_rounded, kind: BtnKind.secondary, busy: _busy, onPressed: _onWhatsApp)),
            ],
          ),
          const SizedBox(height: 14),
          LabeledField('Jumlah dibayar', TextField(
            controller: _paid,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            onChanged: (_) => setState(() {}),
            decoration: deco(null, hint: 'Contoh: 150000', icon: Icons.attach_money_rounded, prefixText: 'Rp '),
          )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in quick)
                ActionChip(
                  label: Text(n == pas ? 'Uang pas ${rp(n)}' : rp(n), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                  backgroundColor: C.soft(context, C.brand50),
                  side: BorderSide.none,
                  onPressed: () => setState(() => _paid.text = num0(n)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: change > 0 ? C.soft(context, C.okBg) : C.bgOf(context), borderRadius: BorderRadius.circular(14)),
            child: SummaryRow('Kembalian', rp(change), bold: true, color: change > 0 ? C.ok : C.mutedOf(context)),
          ),
        ],
      ),
    );
  }

  // ---------- Tampilan baca-saja (Lunas)

  List<Widget> _readonly(Service s) {
    return [
      _card(
        title: 'Cetak Dokumen',
        icon: Icons.print_rounded,
        child: Column(
          children: [
            ActionButton(label: 'Cetak Invoice (A4 / PDF)', icon: Icons.description_rounded, onPressed: () => _printBilling('invoice')),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ActionButton(label: 'Struk', icon: Icons.receipt_long_rounded, kind: BtnKind.secondary, onPressed: () => _printBilling('thermal'))),
                const SizedBox(width: 10),
                Expanded(child: ActionButton(label: 'Work Order', icon: Icons.assignment_rounded, kind: BtnKind.secondary, onPressed: _printWorkOrder)),
              ],
            ),
          ],
        ),
      ),
      _card(
        title: 'Rincian Pekerjaan',
        icon: Icons.build_rounded,
        child: Column(
          children: [
            for (final d in s.details) InfoRow(d.name, rp(d.cost)),
            if (s.parts.isNotEmpty) const Divider(height: 18),
            for (final p in s.parts) InfoRow('${p.name} ×${p.qty}', rp(p.price * p.qty)),
            const Divider(height: 18),
            SummaryRow('Subtotal', rp(s.subtotal)),
            if (s.discountAmount > 0) SummaryRow(s.discount != null ? 'Diskon (${s.discount!.name})' : 'Diskon', '-${rp(s.discountAmount)}', color: C.ok),
            SummaryRow('Pajak', rp(s.taxAmount)),
            const Divider(height: 18),
            SummaryRow('Total', rp(s.total), bold: true, big: true, color: C.brandOf(context)),
            SummaryRow('Dibayar', rp(s.paid)),
            SummaryRow('Kembalian', rp(s.change)),
          ],
        ),
      ),
      if (s.nextRecommendation.isNotEmpty || s.nextDate != null)
        _card(
          title: 'Rekomendasi Berikutnya',
          icon: Icons.tips_and_updates_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.nextRecommendation.isNotEmpty) Text(s.nextRecommendation, style: const TextStyle(height: 1.4)),
              if (s.nextDate != null) ...[const SizedBox(height: 6), InfoRow('Tanggal', fmtDate(s.nextDate))],
            ],
          ),
        ),
    ];
  }

  // ---------- Bar aksi bawah

  Widget? _bottomBar(Service s) {
    Widget wrap(List<Widget> kids) => Container(
          decoration: BoxDecoration(
            color: C.cardOf(context),
            border: Border(top: BorderSide(color: C.lineOf(context))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: Row(children: kids)),
          ),
        );

    switch (s.status) {
      case 'DITERIMA':
        return wrap([
          Expanded(child: ActionButton(label: 'Mulai Kerjakan', icon: Icons.play_arrow_rounded, busy: _busy, onPressed: _start)),
        ]);
      case 'DIKERJAKAN':
        return wrap([
          Expanded(child: ActionButton(label: 'Simpan', icon: Icons.save_rounded, kind: BtnKind.secondary, busy: _busy, onPressed: _onSave)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ActionButton(label: 'Selesai Dikerjakan', icon: Icons.check_circle_rounded, busy: _busy, onPressed: _onFinish)),
        ]);
      case 'MENUNGGU_PEMBAYARAN':
        return wrap([
          Expanded(child: ActionButton(label: 'Simpan', icon: Icons.save_rounded, kind: BtnKind.secondary, busy: _busy, onPressed: _onSave)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ActionButton(label: 'Bayar & Selesai', icon: Icons.payments_rounded, kind: BtnKind.success, busy: _busy, onPressed: _onPay)),
        ]);
      default:
        return Container(
          decoration: BoxDecoration(
            color: C.cardOf(context),
            border: Border(top: BorderSide(color: C.lineOf(context))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionButton(label: 'Kirim Struk via WhatsApp', icon: Icons.chat_rounded, kind: BtnKind.success, busy: _busy, onPressed: _onWhatsApp),
                  const SizedBox(height: 10),
                  ActionButton(label: 'Hapus Transaksi', icon: Icons.delete_outline_rounded, kind: BtnKind.danger, onPressed: _busy ? null : _onDelete),
                ],
              ),
            ),
          ),
        );
    }
  }
}
