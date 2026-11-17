import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import '../../core/settings_provider.dart';
import '../../core/theme.dart';
import '../../print/escpos.dart';
import '../../print/printer.dart';
import '../../print/receipts.dart';
import '../../widgets/common.dart';

/// Pengaturan cetak: cara kirim struk (Bluetooth / jaringan / server / PDF), ukuran kertas, printer, tes cetak.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late PrintMode _mode = PrinterConfig.mode;
  late int _paper = PrinterConfig.paper;
  late final TextEditingController _host = TextEditingController(text: PrinterConfig.lanHost);
  late final TextEditingController _port = TextEditingController(text: '${PrinterConfig.lanPort}');
  bool _testing = false;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _saveLan() async {
    await PrinterConfig.setLan(_host.text, int.tryParse(_port.text.trim()) ?? 9100);
  }

  Future<void> _pickBle() async {
    if (kIsWeb) {
      toast(context, 'Bluetooth hanya tersedia di aplikasi HP Android.', error: true);
      return;
    }
    final r = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _BleScanSheet(),
    );
    if (r != null) {
      await PrinterConfig.setBle(r.$1, r.$2);
      if (mounted) setState(() {});
    }
  }

  Future<void> _test({required bool pdf}) async {
    await _saveLan();
    if (!mounted) return;
    final st = context.read<SettingsProvider>();
    setState(() => _testing = true);
    try {
      if (pdf) {
        // paksa lewat PDF dengan memakai pratinjau
        final shop = PrintService.shop(st);
        final p = await buildTestReceipt(shop);
        final bytes = p.build();
        if (bytes.isNotEmpty && mounted) {
          await PrintService.thermalPreviewOnly(context, p, shop.paperMm, 'Tes Cetak');
        }
      } else {
        await PrintService.thermal(context, st, (shop) => buildTestReceipt(shop), title: 'Tes Cetak');
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Printer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        children: [
          const SectionTitle('Cara Mencetak Struk', padding: EdgeInsets.fromLTRB(2, 4, 2, 10)),
          for (final m in PrintMode.values)
            AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              color: _mode == m ? C.soft(context, C.brand50) : C.cardOf(context),
              borderColor: _mode == m ? C.brandOf(context) : C.lineOf(context),
              onTap: () async {
                setState(() => _mode = m);
                await PrinterConfig.setMode(m);
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_mode == m ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: _mode == m ? C.brandOf(context) : C.mutedOf(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text(m.desc, style: TextStyle(color: C.mutedOf(context), fontSize: 12.5, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SectionTitle('Ukuran Kertas'),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 0, label: Text('Ikuti server (${PrintService.paperMm(st) == 58 ? '58' : '80'} mm)')),
              const ButtonSegment(value: 58, label: Text('58 mm')),
              const ButtonSegment(value: 80, label: Text('80 mm')),
            ],
            selected: {_paper},
            onSelectionChanged: (s) async {
              setState(() => _paper = s.first);
              await PrinterConfig.setPaper(s.first);
            },
          ),
          if (_mode == PrintMode.bluetooth || _mode == PrintMode.auto) ...[
            const SectionTitle('Printer Bluetooth'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconTile(Icons.bluetooth_rounded, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(PrinterConfig.bleId == null ? 'Belum dipilih' : (PrinterConfig.bleName ?? 'Printer'), style: const TextStyle(fontWeight: FontWeight.w800)),
                            if (PrinterConfig.bleId != null) Text(PrinterConfig.bleId!, style: TextStyle(color: C.mutedOf(context), fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ActionButton(label: 'Cari & Pilih Printer', icon: Icons.search_rounded, kind: BtnKind.tonal, onPressed: _pickBle),
                  const SizedBox(height: 8),
                  Text('Nyalakan printer dulu. Printer Bluetooth tidak perlu dipasangkan di pengaturan HP.', style: TextStyle(color: C.mutedOf(context), fontSize: 12)),
                ],
              ),
            ),
          ],
          if (_mode == PrintMode.lan) ...[
            const SectionTitle('Printer Jaringan'),
            AppCard(
              child: Column(
                children: [
                  LabeledField('IP printer', TextField(
                    controller: _host,
                    keyboardType: TextInputType.url,
                    onChanged: (_) => _saveLan(),
                    decoration: deco(null, icon: Icons.router_rounded, hint: '192.168.1.50'),
                  )),
                  const SizedBox(height: 12),
                  LabeledField('Port', TextField(
                    controller: _port,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _saveLan(),
                    decoration: deco(null, icon: Icons.numbers_rounded, hint: '9100'),
                  )),
                ],
              ),
            ),
          ],
          const SectionTitle('Uji Coba'),
          ActionButton(label: 'Cetak Tes ke Printer', icon: Icons.print_rounded, busy: _testing, onPressed: () => _test(pdf: false)),
          const SizedBox(height: 10),
          ActionButton(label: 'Tes lewat PDF', icon: Icons.picture_as_pdf_rounded, kind: BtnKind.secondary, onPressed: _testing ? null : () => _test(pdf: true)),
        ],
      ),
    );
  }
}

/// Sheet pemindai printer Bluetooth (BLE). Mengembalikan (id, nama).
class _BleScanSheet extends StatefulWidget {
  const _BleScanSheet();

  @override
  State<_BleScanSheet> createState() => _BleScanSheetState();
}

class _BleScanSheetState extends State<_BleScanSheet> {
  StreamSubscription<List<ScanResult>>? _sub;
  List<ScanResult> _results = [];
  bool _scanning = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _scanning = true;
      _error = null;
      _results = [];
    });
    try {
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        throw Exception('Bluetooth HP belum aktif. Aktifkan dulu lalu coba lagi.');
      }
      _sub?.cancel();
      _sub = FlutterBluePlus.scanResults.listen((list) {
        final named = list.where((r) => bleNameOf(r).isNotEmpty).toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
        if (mounted) setState(() => _results = named);
      });
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
      await FlutterBluePlus.isScanning.where((s) => s == false).first;
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 42, height: 4, decoration: BoxDecoration(color: C.lineOf(context), borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
            child: Row(
              children: [
                const Expanded(child: Text('Pilih Printer Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                if (_scanning)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                else
                  IconButton(onPressed: _start, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: const TextStyle(color: C.danger, fontWeight: FontWeight.w600))),
          Expanded(
            child: _results.isEmpty
                ? Center(child: Text(_scanning ? 'Mencari printer...' : 'Printer tidak ditemukan. Pastikan printer menyala.', style: TextStyle(color: C.mutedOf(context))))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (context, i) {
                      final r = _results[i];
                      return ListTile(
                        leading: const IconTile(Icons.print_rounded, size: 40),
                        title: Text(bleNameOf(r), style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${r.device.remoteId.str} · sinyal ${r.rssi} dBm', style: const TextStyle(fontSize: 11.5)),
                        onTap: () => Navigator.pop(context, (r.device.remoteId.str, bleNameOf(r))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
