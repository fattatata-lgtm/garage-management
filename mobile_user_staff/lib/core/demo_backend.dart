import 'package:dio/dio.dart';

/// Backend tiruan di dalam app untuk mencoba tampilan TANPA server.
/// Data disimpan di memori selama sesi demo (hilang saat app ditutup).
class DemoError implements Exception {
  DemoError(this.message, [this.status = 400]);
  final String message;
  final int status;
}

class DemoBackend {
  DemoBackend._();
  static bool active = false;
  static _Db _db = _Db();

  static void start() {
    _db = _Db();
    active = true;
  }

  static void stop() => active = false;

  static dynamic handle(RequestOptions o) {
    final seg = o.path.split('/').where((s) => s.isNotEmpty).toList();
    final body = o.data is Map ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};
    return _db.route(o.method.toUpperCase(), seg, o.queryParameters, body);
  }
}

typedef _M = Map<String, dynamic>;

int _int(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
num _num(dynamic v) => v is num ? v : (num.tryParse('$v') ?? 0);
String _iso(DateTime d) => d.toUtc().toIso8601String();
String _s(dynamic v) => (v ?? '').toString();

class _Db {
  _Db() {
    _seed();
  }

  final DateTime now = DateTime.now();
  int _next = 1000;
  int nid() => ++_next;
  final num taxService = 10;
  final num taxSales = 10;

  final _M settings = {
    'businessName': 'Self Automotive',
    'logoUrl': null,
    'address': 'Jl. Raya Bengkel No. 1',
    'phone': '021-1234567',
    'taxService': 10,
    'taxSales': 10,
    'printerType': 'Thermal 58mm',
    'printerConnection': 'BROWSER',
  };
  late List<_M> customers, models, vehicles, categories, suppliers, parts, techs, schedules, types, discounts, services, sales, history;

  // ------------------------------------------------------------------ util
  _M? by(List<_M> l, dynamic id) {
    final i = _int(id);
    for (final m in l) {
      if (m['id'] == i) return m;
    }
    return null;
  }

  _M need(List<_M> l, dynamic id, String what) {
    final m = by(l, id);
    if (m == null) throw DemoError('$what tidak ditemukan.', 404);
    return m;
  }

  String invoice(String prefix, List<_M> list) {
    final d = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final n = list.where((e) => _s(e['invoiceNo']).startsWith('$prefix-$d-')).length + 1;
    return '$prefix-$d-${n.toString().padLeft(4, '0')}';
  }

  String stockStatus(int stock, int low) => stock <= 0 ? 'HABIS' : (stock <= low ? 'RENDAH' : 'BAIK');

  num discountAmount(num subtotal, _M? d) {
    if (d == null || d['status'] != 'AKTIF') return 0;
    return d['type'] == 'PERCENTAGE' ? subtotal * _num(d['value']) / 100 : _num(d['value']);
  }

  // ------------------------------------------------------------------ views
  _M spView(_M sp) => {
        ...sp,
        'category': by(categories, sp['categoryId']),
        'supplier': sp['supplierId'] == null ? null : by(suppliers, sp['supplierId']),
        'status': stockStatus(_int(sp['stock']), _int(sp['lowStockThreshold'])),
      };

  _M histView(_M h) => {
        ...h,
        'sparepart': by(parts, h['sparepartId']),
        'supplier': h['supplierId'] == null ? null : by(suppliers, h['supplierId']),
      };

  _M vehView(_M v) => {...v, 'customer': by(customers, v['customerId']), 'vehicleModel': by(models, v['vehicleModelId'])};

  _M svcView(_M s, {bool full = false}) {
    final v = by(vehicles, s['vehicleId']);
    return {
      ...s,
      'vehicle': v == null ? null : vehView(v),
      'technician': by(techs, s['technicianId']),
      'discount': s['discountId'] == null ? null : by(discounts, s['discountId']),
      'spareparts': (s['parts'] as List).map((p) => {'sparepartId': p['sparepartId'], 'qty': p['qty'], 'price': p['price'], 'sparepart': by(parts, p['sparepartId'])}).toList(),
      'logs': full ? s['logs'] : <dynamic>[],
    };
  }

  _M saleView(_M s) => {
        ...s,
        'customer': s['customerId'] == null ? null : by(customers, s['customerId']),
        'discount': s['discountId'] == null ? null : by(discounts, s['discountId']),
        'items': (s['items'] as List).map((p) => {'sparepartId': p['sparepartId'], 'qty': p['qty'], 'price': p['price'], 'sparepart': by(parts, p['sparepartId'])}).toList(),
      };

  void recalcService(_M s) {
    num sub = 0;
    for (final d in (s['details'] as List)) {
      sub += _num(d['cost']);
    }
    for (final p in (s['parts'] as List)) {
      sub += _num(p['price']) * _int(p['qty']);
    }
    final disc = discountAmount(sub, by(discounts, s['discountId']));
    num after = sub - disc;
    if (after < 0) after = 0;
    final tax = after * taxService / 100;
    s['subtotal'] = sub;
    s['discountAmount'] = disc;
    s['taxAmount'] = tax;
    s['total'] = after + tax;
  }

  void log(_M s, String? status, String title, [String? note]) {
    (s['logs'] as List).add({'status': status, 'title': title, 'note': note, 'actor': 'staff', 'createdAt': _iso(DateTime.now())});
  }

  void addHistory(int spId, String dir, String source, int qty, String? note, String? ref, {int? supplierId}) {
    history.insert(0, {'id': nid(), 'sparepartId': spId, 'supplierId': supplierId, 'direction': dir, 'source': source, 'quantity': qty, 'note': note, 'refInvoice': ref, 'createdAt': _iso(DateTime.now())});
  }

  // ------------------------------------------------------------------ seed
  void _seed() {
    DateTime ago({int d = 0, int h = 0}) => now.subtract(Duration(days: d, hours: h));

    customers = [
      {'id': 1, 'name': 'Hendra Wijaya', 'phone': '081234567801', 'email': 'hendra@mail.com', 'address': 'Jl. Merdeka No. 10, Malang'},
      {'id': 2, 'name': 'Siti Rahmawati', 'phone': '082233445502', 'email': null, 'address': 'Jl. Sudirman No. 45'},
      {'id': 3, 'name': 'Budi Prasetyo', 'phone': '085712345603', 'email': 'budi.p@mail.com', 'address': null},
      {'id': 4, 'name': 'Dewi Lestari', 'phone': '081998877604', 'email': null, 'address': 'Perum Griya Asri Blok C2'},
      {'id': 5, 'name': 'Rizky Ramadhan', 'phone': '087755443305', 'email': null, 'address': null},
    ];
    models = [
      {'id': 1, 'brand': 'Toyota', 'model': 'Avanza', 'year': 2018, 'type': 'MPV', 'wheels': 4},
      {'id': 2, 'brand': 'Honda', 'model': 'Brio', 'year': 2020, 'type': 'Hatchback', 'wheels': 4},
      {'id': 3, 'brand': 'Honda', 'model': 'Vario 150', 'year': 2021, 'type': 'Skutik', 'wheels': 2},
      {'id': 4, 'brand': 'Mitsubishi', 'model': 'Xpander', 'year': 2019, 'type': 'MPV', 'wheels': 4},
      {'id': 5, 'brand': 'Suzuki', 'model': 'Ertiga', 'year': 2017, 'type': 'MPV', 'wheels': 4},
      {'id': 6, 'brand': 'Yamaha', 'model': 'NMAX', 'year': 2022, 'type': 'Skutik', 'wheels': 2},
    ];
    vehicles = [
      {'id': 1, 'customerId': 1, 'vehicleModelId': 1, 'plateNumber': 'N 1234 AB', 'vin': 'MHKA1BA1JJK000123', 'engineNumber': '1NRF123456', 'color': 'Putih', 'purchaseYear': 2018, 'note': null},
      {'id': 2, 'customerId': 2, 'vehicleModelId': 2, 'plateNumber': 'N 5678 CD', 'vin': null, 'engineNumber': null, 'color': 'Merah', 'purchaseYear': 2020, 'note': null},
      {'id': 3, 'customerId': 3, 'vehicleModelId': 3, 'plateNumber': 'N 3344 EF', 'vin': null, 'engineNumber': null, 'color': 'Hitam', 'purchaseYear': 2021, 'note': null},
      {'id': 4, 'customerId': 4, 'vehicleModelId': 4, 'plateNumber': 'AG 9012 GH', 'vin': null, 'engineNumber': null, 'color': 'Abu-abu', 'purchaseYear': 2019, 'note': 'Sering dipakai luar kota'},
      {'id': 5, 'customerId': 1, 'vehicleModelId': 6, 'plateNumber': 'N 7788 IJ', 'vin': null, 'engineNumber': null, 'color': 'Biru', 'purchaseYear': 2022, 'note': null},
      {'id': 6, 'customerId': 5, 'vehicleModelId': 5, 'plateNumber': 'N 2468 KL', 'vin': null, 'engineNumber': null, 'color': 'Silver', 'purchaseYear': 2017, 'note': null},
    ];
    categories = [
      {'id': 1, 'name': 'Oli & Pelumas'},
      {'id': 2, 'name': 'Rem'},
      {'id': 3, 'name': 'Filter'},
      {'id': 4, 'name': 'Kelistrikan'},
      {'id': 5, 'name': 'Ban & Velg'},
    ];
    suppliers = [
      {'id': 1, 'name': 'PT Sumber Oli Jaya', 'contactPerson': 'Pak Darmawan', 'phone': '081234000111', 'email': 'sales@sumberoli.test', 'address': 'Jl. Industri No. 5, Surabaya', 'note': 'Pembayaran tempo 14 hari'},
      {'id': 2, 'name': 'CV Rem Prima', 'contactPerson': 'Bu Lestari', 'phone': '082155500222', 'email': null, 'address': 'Jl. Raya Gubeng 12, Surabaya', 'note': null},
      {'id': 3, 'name': 'Toko Kelistrikan Maju', 'contactPerson': null, 'phone': '085733300333', 'email': null, 'address': null, 'note': 'Kirim tiap hari Selasa'},
    ];
    _M sp(int id, String code, String name, int cat, num buy, num sell, int stock, int low, [int? sup]) =>
        {'id': id, 'code': code, 'name': name, 'categoryId': cat, 'supplierId': sup, 'buyPrice': buy, 'sellPrice': sell, 'stock': stock, 'lowStockThreshold': low};
    parts = [
      sp(1, 'OLI-001', 'Oli Mesin 10W-40 1L', 1, 55000, 75000, 24, 5, 1),
      sp(2, 'OLI-002', 'Oli Mesin Matic 0.8L', 1, 38000, 52000, 3, 5, 1),
      sp(3, 'RM-001', 'Kampas Rem Depan Avanza', 2, 110000, 165000, 8, 3, 2),
      sp(4, 'RM-002', 'Kampas Rem Belakang Vario', 2, 45000, 70000, 0, 3, 2),
      sp(5, 'FLT-001', 'Filter Oli Universal', 3, 22000, 38000, 15, 5, 1),
      sp(6, 'FLT-002', 'Filter Udara Xpander', 3, 60000, 95000, 2, 4),
      sp(7, 'KLS-001', 'Busi NGK Iridium', 4, 48000, 72000, 20, 6, 3),
      sp(8, 'KLS-002', 'Aki GS 45Ah', 4, 620000, 780000, 4, 2, 3),
      sp(9, 'BAN-001', 'Ban Dalam 17"', 5, 35000, 55000, 0, 3),
      sp(10, 'OLI-003', 'Minyak Rem DOT 3', 1, 18000, 30000, 12, 5, 1),
    ];
    techs = [
      {'id': 1, 'name': 'Budi Santoso', 'skill': 'Mesin & Tune Up', 'status': 'AKTIF'},
      {'id': 2, 'name': 'Agus Wijaya', 'skill': 'Kelistrikan', 'status': 'AKTIF'},
      {'id': 3, 'name': 'Rudi Hartono', 'skill': 'Body & Rem', 'status': 'AKTIF'},
      {'id': 4, 'name': 'Joko Susilo', 'skill': 'Mekanik Umum', 'status': 'NONAKTIF'},
    ];
    schedules = [
      {'id': 1, 'technicianId': 1, 'date': _iso(now.add(const Duration(days: 1))), 'note': 'Servis armada kantor'},
      {'id': 2, 'technicianId': 2, 'date': _iso(now.add(const Duration(days: 3))), 'note': null},
    ];
    _M ty(int id, String n, String d, num c) => {'id': id, 'name': n, 'description': d, 'estimatedCost': c};
    types = [
      ty(1, 'Servis Berkala', 'Pengecekan menyeluruh sesuai jadwal', 150000),
      ty(2, 'Ganti Oli Mesin', 'Jasa penggantian oli + pengecekan', 35000),
      ty(3, 'Tune Up', 'Penyetelan mesin & pembersihan', 250000),
      ty(4, 'Spooring & Balancing', 'Penyetelan roda', 200000),
      ty(5, 'Servis Rem', 'Pembersihan & penggantian kampas', 120000),
      ty(6, 'Kuras Radiator', 'Pengurasan & isi coolant', 100000),
    ];
    discounts = [
      {'id': 1, 'name': 'Promo Member', 'code': 'MEMBER5', 'type': 'PERCENTAGE', 'value': 5, 'status': 'AKTIF', 'scope': 'SEMUA'},
      {'id': 2, 'name': 'Potongan Rp20.000', 'code': 'HEMAT20', 'type': 'NOMINAL', 'value': 20000, 'status': 'AKTIF', 'scope': 'SERVICE'},
    ];

    _M svc(int id, int veh, int tech, DateTime date, String status, String complaint,
        {int? km, List<_M> details = const [], List<_M> items = const [], String rec = '', bool pay = false}) {
      final s = <String, dynamic>{
        'id': id, 'invoiceNo': 'SVC-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${id.toString().padLeft(4, '0')}',
        'vehicleId': veh, 'technicianId': tech, 'date': _iso(date), 'km': km, 'complaint': complaint, 'internalNote': '',
        'status': status, 'discountId': null, 'nextServiceRecommendation': rec, 'nextServiceDate': null,
        'subtotal': 0, 'discountAmount': 0, 'taxAmount': 0, 'total': 0, 'paid': 0, 'change': 0,
        'details': details, 'parts': items, 'logs': <dynamic>[],
      };
      recalcService(s);
      const order = ['DITERIMA', 'DIKERJAKAN', 'MENUNGGU_PEMBAYARAN', 'SELESAI'];
      const titles = ['Tahap 1 - Service diterima', 'Tahap 2 - Mulai dikerjakan', 'Tahap 3 - Selesai dikerjakan, menunggu pembayaran', 'Tahap 4 - Pembayaran diterima, transaksi Selesai (Lunas)'];
      for (var i = 0; i <= order.indexOf(status); i++) {
        (s['logs'] as List).add({'status': order[i], 'title': titles[i], 'note': i == 0 ? complaint : null, 'actor': 'staff', 'createdAt': _iso(date.add(Duration(minutes: 20 * i)))});
      }
      if (pay) {
        final total = _num(s['total']);
        s['paid'] = (total / 50000).ceil() * 50000;
        s['change'] = _num(s['paid']) - total;
      }
      return s;
    }

    _M d(String n, num c) => {'name': n, 'description': null, 'cost': c};
    _M p(int id, int qty) => {'sparepartId': id, 'qty': qty, 'price': by(parts, id)!['sellPrice']};

    services = [
      svc(1, 1, 1, ago(h: 2), 'MENUNGGU_PEMBAYARAN', 'Servis berkala 45.000 km, rem agak bunyi.',
          km: 45200, details: [d('Ganti Oli Mesin', 35000), d('Servis Rem', 120000)], items: [p(1, 1), p(5, 1), p(3, 1)], rec: 'Ganti kampas rem belakang & cek aki dalam 3 bulan.'),
      svc(2, 3, 2, ago(h: 1), 'DIKERJAKAN', 'Mesin brebet, susah starter pagi hari.', km: 12000, details: [d('Servis Berkala', 150000)], items: [p(7, 1)]),
      svc(3, 2, 1, ago(h: 0), 'DITERIMA', 'Mesin kasar saat idle, minta dicek.'),
      svc(4, 4, 3, ago(h: 5), 'SELESAI', 'Tune up rutin sebelum mudik.', km: 38000, details: [d('Tune Up', 250000)], items: [p(7, 4), p(1, 1)], pay: true, rec: 'Ganti filter udara 5.000 km lagi.'),
      svc(5, 5, 2, ago(d: 2), 'SELESAI', 'Ganti oli.', km: 8000, details: [d('Ganti Oli Mesin', 35000)], items: [p(2, 1)], pay: true),
      svc(6, 6, 1, ago(d: 1), 'DITERIMA', 'AC kurang dingin dan ada bunyi saat belok.'),
    ];

    _M sale(int id, int? cust, String? walk, DateTime date, List<_M> items) {
      final s = <String, dynamic>{
        'id': id, 'invoiceNo': 'SLS-${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}-${id.toString().padLeft(4, '0')}',
        'customerId': cust, 'walkInName': walk, 'date': _iso(date), 'discountId': null, 'items': items,
        'subtotal': 0, 'discountAmount': 0, 'taxAmount': 0, 'total': 0, 'paid': 0, 'change': 0,
      };
      _recalcSale(s);
      s['paid'] = (_num(s['total']) / 50000).ceil() * 50000;
      s['change'] = _num(s['paid']) - _num(s['total']);
      return s;
    }

    sales = [
      sale(1, null, 'Pelanggan Umum', ago(h: 3), [p(1, 2), p(5, 1)]),
      sale(2, 3, null, ago(d: 1), [p(7, 2)]),
      sale(3, null, 'Pelanggan Umum', ago(d: 3), [p(10, 3)]),
    ];

    history = [];
    for (final x in parts) {
      addHistory(_int(x['id']), 'MASUK', 'MANUAL', _int(x['stock']) + 5, 'Stok awal', null, supplierId: x['supplierId'] as int?);
    }
    addHistory(1, 'KELUAR', 'PENJUALAN', 2, 'Terjual pada invoice ${sales[0]['invoiceNo']}', _s(sales[0]['invoiceNo']));
    addHistory(7, 'KELUAR', 'SERVICE', 4, 'Dipakai pada service ${services[3]['invoiceNo']}', _s(services[3]['invoiceNo']));
  }

  void _recalcSale(_M s, {_M? disc}) {
    num sub = 0;
    for (final it in (s['items'] as List)) {
      sub += _num(it['price']) * _int(it['qty']);
    }
    final dc = discountAmount(sub, disc ?? by(discounts, s['discountId']));
    num after = sub - dc;
    if (after < 0) after = 0;
    final tax = after * taxSales / 100;
    s['subtotal'] = sub;
    s['discountAmount'] = dc;
    s['taxAmount'] = tax;
    s['total'] = after + tax;
  }

  // ------------------------------------------------------------------ router
  dynamic route(String m, List<String> seg, _M q, _M body) {
    if (seg.isEmpty) return <String, dynamic>{};
    final r = seg[0];
    switch (r) {
      case 'auth':
        return {'id': 1, 'username': 'staff', 'email': 'staff@selfautomotive.test', 'role': 'STAFF'};
      case 'settings':
        if (seg.length > 1 && seg[1] == 'logo') {
          if (m == 'DELETE') settings['logoUrl'] = null;
          return settings;
        }
        if (m == 'PUT') {
          final name = _s(body['businessName']).trim();
          if (body.containsKey('businessName') && name.isEmpty) throw DemoError('Nama bengkel tidak boleh kosong.');
          for (final k in ['businessName', 'address', 'phone', 'printerType']) {
            if (body[k] != null) settings[k] = k == 'businessName' ? name : body[k];
          }
          for (final k in ['taxService', 'taxSales']) {
            if (body[k] != null) settings[k] = _num(body[k]);
          }
        }
        return settings;
      case 'dashboard':
        return _dashboard(_s(q['period']));
      case 'services':
        return _services(m, seg, q, body);
      case 'sales':
        return _sales(m, seg, q, body);
      case 'spareparts':
        return _spareparts(m, seg, q, body);
      case 'customers':
        return _customers(m, seg, q, body);
      case 'vehicles':
        return _vehicles(m, seg, q, body);
      case 'vehicle-models':
        return _simple(m, seg, models, body, {'brand', 'model', 'year', 'type', 'wheels'}, (e) => e);
      case 'categories':
        return _categories(m, seg, body);
      case 'suppliers':
        return _suppliers(m, seg, q, body);
      case 'technicians':
        return _techs(m, seg, q, body);
      case 'service-types':
        return _simple(m, seg, types, body, {'name', 'description', 'estimatedCost'}, (e) => e);
      case 'discounts':
        return _discountRoute(m, seg, q, body);
      case 'print':
        return {'ok': true};
      case 'reports':
        return _reports(seg.length > 1 ? seg[1] : '', q);
    }
    throw DemoError('Endpoint demo tidak tersedia: /${seg.join('/')}', 404);
  }

  // Generic CRUD sederhana
  dynamic _simple(String m, List<String> seg, List<_M> list, _M body, Set<String> fields, _M Function(_M) view) {
    if (m == 'GET') return list.map(view).toList();
    if (m == 'POST') {
      final e = <String, dynamic>{'id': nid()};
      for (final f in fields) {
        e[f] = body[f];
      }
      list.add(e);
      return e;
    }
    final e = need(list, seg[1], 'Data');
    if (m == 'PUT') {
      for (final f in fields) {
        if (body.containsKey(f)) e[f] = body[f];
      }
      return e;
    }
    if (m == 'DELETE') {
      if (list == models && vehicles.any((v) => v['vehicleModelId'] == e['id'])) throw DemoError('Masih dipakai data kendaraan.');
      list.remove(e);
      return {'message': 'Berhasil dihapus.'};
    }
    return e;
  }

  dynamic _categories(String m, List<String> seg, _M body) {
    _M view(_M c) => {...c, '_count': {'spareparts': parts.where((p) => p['categoryId'] == c['id']).length}};
    if (m == 'GET') return categories.map(view).toList();
    if (m == 'POST') {
      final c = {'id': nid(), 'name': body['name']};
      categories.add(c);
      return c;
    }
    final c = need(categories, seg[1], 'Kategori');
    if (m == 'PUT') {
      c['name'] = body['name'];
      return c;
    }
    if (parts.any((p) => p['categoryId'] == c['id'])) throw DemoError('Kategori masih dipakai sparepart.');
    categories.remove(c);
    return {'message': 'Kategori berhasil dihapus.'};
  }

  dynamic _discountRoute(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        var list = discounts.reversed.toList(); // terbaru dulu, seperti server
        if (q['activeOnly'] == 'true') list = list.where((e) => e['status'] == 'AKTIF').toList();
        return list;
      }
      if (_s(body['name']).trim().isEmpty || _s(body['type']).isEmpty || body['value'] == null) {
        throw DemoError('Nama, tipe, dan nilai diskon wajib diisi.');
      }
      final code = _s(body['code']).trim();
      final d = <String, dynamic>{
        'id': nid(),
        'name': _s(body['name']).trim(),
        'code': code.isEmpty ? null : code,
        'type': body['type'],
        'value': _num(body['value']),
        'status': body['status'] ?? 'AKTIF',
        'scope': body['scope'] ?? 'SEMUA',
      };
      discounts.add(d);
      return d;
    }
    final d = need(discounts, seg[1], 'Diskon');
    if (m == 'PUT') {
      for (final f in ['name', 'type', 'status', 'scope']) {
        if (body[f] != null) d[f] = body[f];
      }
      if (body['value'] != null) d['value'] = _num(body['value']);
      final code = _s(body['code']).trim();
      d['code'] = code.isEmpty ? null : code;
      return d;
    }
    if (m == 'DELETE') {
      discounts.remove(d);
      return {'message': 'Diskon berhasil dihapus.'};
    }
    return d;
  }

  dynamic _suppliers(String m, List<String> seg, _M q, _M body) {
    _M view(_M x) => {...x, '_count': {'spareparts': parts.where((p) => p['supplierId'] == x['id']).length}};
    String? clean(dynamic v) {
      final t = _s(v).trim();
      return t.isEmpty ? null : t;
    }

    if (seg.length == 1) {
      if (m == 'GET') {
        final k = _s(q['q']).toLowerCase();
        final list = suppliers
            .where((x) => k.isEmpty || _s(x['name']).toLowerCase().contains(k) || _s(x['contactPerson']).toLowerCase().contains(k) || _s(x['phone']).toLowerCase().contains(k))
            .toList()
          ..sort((a, b) => _s(a['name']).toLowerCase().compareTo(_s(b['name']).toLowerCase()));
        return list.map(view).toList();
      }
      if (_s(body['name']).trim().isEmpty) throw DemoError('Nama supplier wajib diisi.');
      final x = <String, dynamic>{
        'id': nid(),
        'name': _s(body['name']).trim(),
        'contactPerson': clean(body['contactPerson']),
        'phone': clean(body['phone']),
        'email': clean(body['email']),
        'address': clean(body['address']),
        'note': clean(body['note']),
      };
      suppliers.add(x);
      return view(x);
    }
    final x = need(suppliers, seg[1], 'Supplier');
    if (m == 'PUT') {
      if (body.containsKey('name') && _s(body['name']).trim().isEmpty) throw DemoError('Nama supplier wajib diisi.');
      if (body.containsKey('name')) x['name'] = _s(body['name']).trim();
      for (final f in ['contactPerson', 'phone', 'email', 'address', 'note']) {
        if (body.containsKey(f)) x[f] = clean(body[f]);
      }
      return view(x);
    }
    if (m == 'DELETE') {
      // Sama dengan server: sparepart & riwayat stok terkait dilepas (supplierId -> null), datanya tidak ikut terhapus.
      for (final p in parts) {
        if (p['supplierId'] == x['id']) p['supplierId'] = null;
      }
      for (final h in history) {
        if (h['supplierId'] == x['id']) h['supplierId'] = null;
      }
      suppliers.remove(x);
      return {'message': 'Supplier berhasil dihapus.'};
    }
    return view(x);
  }

  // ------------------------------------------------------------------ dashboard
  dynamic _dashboard(String period) {
    final n = DateTime.now();
    DateTime start;
    if (period == 'week') {
      start = DateTime(n.year, n.month, n.day).subtract(Duration(days: (n.weekday - 1)));
    } else if (period == 'month') {
      start = DateTime(n.year, n.month, 1);
    } else {
      start = DateTime(n.year, n.month, n.day);
    }
    bool inRange(dynamic iso) => DateTime.parse(_s(iso)).toLocal().isAfter(start.subtract(const Duration(seconds: 1)));
    final svcs = services.where((s) => inRange(s['date'])).toList();
    final done = svcs.where((s) => s['status'] == 'SELESAI');
    final sl = sales.where((s) => inRange(s['date'])).toList();
    num pService = 0, pSales = 0, laba = 0;
    for (final s in done) {
      pService += _num(s['total']);
    }
    for (final s in sl) {
      pSales += _num(s['total']);
      for (final it in (s['items'] as List)) {
        laba += (_num(it['price']) - _num(by(parts, it['sparepartId'])!['buyPrice'])) * _int(it['qty']);
      }
    }
    final sorted = [...services]..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
    return {
      'period': period,
      'totalCustomers': customers.length,
      'totalVehicles': vehicles.length,
      'totalServices': svcs.length,
      'pendapatanService': pService,
      'pendapatanSales': pSales,
      'totalPendapatan': pService + pSales,
      'labaEstimasi': laba,
      'lowStockAlerts': parts.map(spView).where((p) => p['status'] != 'BAIK').toList(),
      'recentServices': sorted.take(8).map((s) => svcView(s)).toList(),
    };
  }

  // ------------------------------------------------------------------ services
  dynamic _services(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        var list = [...services];
        if (q['status'] != null) list = list.where((s) => s['status'] == q['status']).toList();
        list.sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
        return list.map((s) => svcView(s)).toList();
      }
      // POST - tahap 1
      if (body['vehicleId'] == null || body['technicianId'] == null || _s(body['complaint']).isEmpty) {
        throw DemoError('Kendaraan, teknisi, tanggal service, dan keluhan wajib diisi.');
      }
      final s = <String, dynamic>{
        'id': nid(), 'invoiceNo': invoice('SVC', services), 'vehicleId': _int(body['vehicleId']), 'technicianId': _int(body['technicianId']),
        'date': body['date'] ?? _iso(DateTime.now()), 'km': null, 'complaint': body['complaint'], 'internalNote': '', 'status': 'DITERIMA',
        'discountId': null, 'nextServiceRecommendation': '', 'nextServiceDate': null,
        'subtotal': 0, 'discountAmount': 0, 'taxAmount': 0, 'total': 0, 'paid': 0, 'change': 0, 'details': <dynamic>[], 'parts': <dynamic>[], 'logs': <dynamic>[],
      };
      log(s, 'DITERIMA', 'Tahap 1 - Service diterima', _s(body['complaint']));
      services.add(s);
      return svcView(s, full: true);
    }

    final s = need(services, seg[1], 'Transaksi service');
    final action = seg.length > 2 ? seg[2] : '';

    if (action == 'whatsapp-message') {
      final c = by(customers, by(vehicles, s['vehicleId'])!['customerId'])!;
      return {'phone': c['phone'], 'message': 'Halo ${c['name']}, ini pesan DEMO untuk service ${s['invoiceNo']}. Terima kasih.'};
    }
    if (m == 'GET') return svcView(s, full: true);
    if (m == 'DELETE') {
      for (final p in (s['parts'] as List)) {
        final spx = by(parts, p['sparepartId']);
        if (spx != null) spx['stock'] = _int(spx['stock']) + _int(p['qty']);
      }
      services.remove(s);
      return {'message': 'Transaksi service berhasil dihapus.'};
    }
    if (s['status'] == 'SELESAI' && m != 'GET') throw DemoError('Transaksi yang sudah Selesai (Lunas) tidak dapat diubah.');

    if (action == 'start') {
      if (s['status'] != 'DITERIMA') throw DemoError('Hanya transaksi berstatus Diterima yang bisa dimulai.');
      s['status'] = 'DIKERJAKAN';
      log(s, 'DIKERJAKAN', 'Tahap 2 - Mulai dikerjakan');
      return svcView(s, full: true);
    }
    if (action == 'finish-work') {
      if ((s['details'] as List).isEmpty) throw DemoError('Simpan minimal 1 detail service (jasa) terlebih dahulu.');
      if (s['km'] == null) throw DemoError('Kilometer kendaraan wajib diisi dan disimpan terlebih dahulu.');
      s['status'] = 'MENUNGGU_PEMBAYARAN';
      log(s, 'MENUNGGU_PEMBAYARAN', 'Tahap 3 - Selesai dikerjakan, menunggu pembayaran');
      return svcView(s, full: true);
    }
    if (action == 'complete') {
      final paid = _num(body['paid']);
      if (paid < _num(s['total'])) throw DemoError('Jumlah dibayar wajib diisi dan tidak boleh kurang dari total.');
      s['status'] = 'SELESAI';
      s['paid'] = paid;
      s['change'] = paid - _num(s['total']);
      log(s, 'SELESAI', 'Tahap 4 - Pembayaran diterima, transaksi Selesai (Lunas)');
      return svcView(s, full: true);
    }
    if (action == 'work') return _saveWork(s, body);

    // PUT - edit data awal
    s['vehicleId'] = _int(body['vehicleId']);
    s['technicianId'] = _int(body['technicianId']);
    s['date'] = body['date'] ?? s['date'];
    s['complaint'] = body['complaint'];
    log(s, _s(s['status']), 'Data service diubah');
    return svcView(s, full: true);
  }

  dynamic _saveWork(_M s, _M body) {
    for (final old in (s['parts'] as List)) {
      final spx = by(parts, old['sparepartId']);
      if (spx != null) spx['stock'] = _int(spx['stock']) + _int(old['qty']);
    }
    final newParts = <_M>[];
    for (final p in ((body['spareparts'] as List?) ?? const [])) {
      final spx = need(parts, p['sparepartId'], 'Sparepart');
      final qty = _int(p['qty']);
      if (qty <= 0) continue;
      if (_int(spx['stock']) < qty) {
        // kembalikan keadaan stok sebelum gagal
        for (final old in (s['parts'] as List)) {
          final o = by(parts, old['sparepartId']);
          if (o != null) o['stock'] = _int(o['stock']) - _int(old['qty']);
        }
        throw DemoError('Stok ${spx['name']} tidak mencukupi (tersedia ${spx['stock']}).');
      }
      spx['stock'] = _int(spx['stock']) - qty;
      addHistory(_int(spx['id']), 'KELUAR', 'SERVICE', qty, 'Dipakai pada service ${s['invoiceNo']}', _s(s['invoiceNo']));
      newParts.add({'sparepartId': spx['id'], 'qty': qty, 'price': p['price'] ?? spx['sellPrice']});
    }
    s['parts'] = newParts;
    s['details'] = ((body['details'] as List?) ?? const [])
        .where((d) => _s(d['name']).isNotEmpty)
        .map((d) => {'name': d['name'], 'description': d['description'], 'cost': _num(d['cost'])})
        .toList();
    if (body['km'] != null) s['km'] = _int(body['km']);
    s['nextServiceRecommendation'] = _s(body['nextServiceRecommendation']);
    s['nextServiceDate'] = body['nextServiceDate'];
    s['internalNote'] = _s(body['internalNote']);
    if (body.containsKey('discountId')) s['discountId'] = body['discountId'];
    recalcService(s);
    log(s, _s(s['status']), s['status'] == 'DIKERJAKAN' ? 'Detail pengerjaan disimpan' : 'Rincian tagihan diperbarui');
    return svcView(s, full: true);
  }

  // ------------------------------------------------------------------ sales
  dynamic _sales(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        final list = [...sales]..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
        return list.map(saleView).toList();
      }
      final items = (body['items'] as List?) ?? const [];
      if (items.isEmpty) throw DemoError('Minimal 1 item sparepart wajib ditambahkan.');
      final prepared = <_M>[];
      for (final it in items) {
        final spx = need(parts, it['sparepartId'], 'Sparepart');
        final qty = _int(it['qty']);
        if (_int(spx['stock']) < qty) throw DemoError('Stok ${spx['name']} tidak mencukupi (tersedia ${spx['stock']}).');
        prepared.add({'sparepartId': spx['id'], 'qty': qty, 'price': spx['sellPrice']});
      }
      final s = <String, dynamic>{
        'id': nid(), 'invoiceNo': invoice('SLS', sales), 'customerId': body['customerId'], 'walkInName': body['customerId'] == null ? (body['walkInName'] ?? 'Pelanggan Umum') : null,
        'date': _iso(DateTime.now()), 'discountId': body['discountId'], 'items': prepared, 'subtotal': 0, 'discountAmount': 0, 'taxAmount': 0, 'total': 0, 'paid': 0, 'change': 0,
      };
      _recalcSale(s);
      final paid = _num(body['paid']);
      if (paid < _num(s['total'])) throw DemoError('Jumlah dibayar wajib diisi dan tidak boleh kurang dari total.');
      s['paid'] = paid;
      s['change'] = paid - _num(s['total']);
      for (final p in prepared) {
        final spx = by(parts, p['sparepartId'])!;
        spx['stock'] = _int(spx['stock']) - _int(p['qty']);
        addHistory(_int(spx['id']), 'KELUAR', 'PENJUALAN', _int(p['qty']), 'Terjual pada invoice ${s['invoiceNo']}', _s(s['invoiceNo']));
      }
      sales.add(s);
      return saleView(s);
    }
    final s = need(sales, seg[1], 'Transaksi penjualan');
    if (seg.length > 2 && seg[2] == 'whatsapp-message') {
      final c = s['customerId'] == null ? null : by(customers, s['customerId']);
      return {'phone': c?['phone'], 'message': 'Struk DEMO ${s['invoiceNo']}. Terima kasih.'};
    }
    if (m == 'DELETE') {
      for (final it in (s['items'] as List)) {
        final spx = by(parts, it['sparepartId']);
        if (spx != null) spx['stock'] = _int(spx['stock']) + _int(it['qty']);
      }
      sales.remove(s);
      return {'message': 'Transaksi penjualan berhasil dihapus.'};
    }
    return saleView(s);
  }

  // ------------------------------------------------------------------ spareparts
  dynamic _spareparts(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        final k = _s(q['q']).toLowerCase();
        final catQ = q['categoryId'] == null || _s(q['categoryId']).isEmpty ? null : _int(q['categoryId']);
        final supQ = q['supplierId'] == null || _s(q['supplierId']).isEmpty ? null : _int(q['supplierId']);
        final stQ = _s(q['stockStatus']);
        var list = parts
            .where((p) =>
                (k.isEmpty || _s(p['name']).toLowerCase().contains(k) || _s(p['code']).toLowerCase().contains(k)) &&
                (catQ == null || p['categoryId'] == catQ) &&
                (supQ == null || p['supplierId'] == supQ) &&
                (stQ.isEmpty || stockStatus(_int(p['stock']), _int(p['lowStockThreshold'])) == stQ))
            .toList();
        list.sort((a, b) => _s(a['name']).compareTo(_s(b['name'])));
        return list.map(spView).toList();
      }
      if (parts.any((p) => _s(p['code']).toLowerCase() == _s(body['code']).toLowerCase())) throw DemoError('Kode sparepart sudah dipakai.');
      final sp = <String, dynamic>{
        'id': nid(), 'code': body['code'], 'name': body['name'], 'categoryId': _int(body['categoryId']),
        'supplierId': body['supplierId'] == null || _s(body['supplierId']).isEmpty ? null : _int(body['supplierId']), 'buyPrice': _num(body['buyPrice']),
        'sellPrice': _num(body['sellPrice']), 'stock': _int(body['stock']), 'lowStockThreshold': body['lowStockThreshold'] == null ? 5 : _int(body['lowStockThreshold']),
      };
      parts.add(sp);
      return spView(sp);
    }
    if (seg[1] == 'history') {
      return history.take(200).map(histView).toList();
    }
    final sp = need(parts, seg[1], 'Sparepart');
    if (seg.length > 2 && seg[2] == 'stock-move') {
      final qty = _int(body['quantity']);
      final dir = _s(body['direction']);
      if (qty <= 0 || (dir != 'MASUK' && dir != 'KELUAR')) throw DemoError('Arah stok dan jumlah (>0) wajib diisi dengan benar.');
      if (dir == 'KELUAR' && _int(sp['stock']) < qty) throw DemoError('Stok tidak mencukupi untuk dikurangi.');
      sp['stock'] = dir == 'MASUK' ? _int(sp['stock']) + qty : _int(sp['stock']) - qty;
      // Supplier hanya relevan untuk barang masuk (sama dengan server).
      final supId = dir == 'MASUK' && body['supplierId'] != null && _s(body['supplierId']).isNotEmpty ? _int(body['supplierId']) : null;
      addHistory(_int(sp['id']), dir, 'MANUAL', qty, body['note'] as String?, null, supplierId: supId);
      return spView(sp);
    }
    if (m == 'PUT') {
      for (final f in ['code', 'name', 'categoryId', 'buyPrice', 'sellPrice', 'lowStockThreshold']) {
        if (body.containsKey(f)) sp[f] = body[f];
      }
      // supplierId null / '' = lepas supplier; tidak dikirim = tidak diubah
      if (body.containsKey('supplierId')) {
        sp['supplierId'] = body['supplierId'] == null || _s(body['supplierId']).isEmpty ? null : _int(body['supplierId']);
      }
      return spView(sp);
    }
    if (m == 'DELETE') {
      parts.remove(sp);
      return {'message': 'Sparepart berhasil dihapus.'};
    }
    return {...spView(sp), 'stockHistory': history.where((h) => h['sparepartId'] == sp['id']).take(100).map(histView).toList()};
  }

  // ------------------------------------------------------------------ customers & vehicles
  dynamic _customers(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        return customers.map((c) => {...c, '_count': {'vehicles': vehicles.where((v) => v['customerId'] == c['id']).length}}).toList().reversed.toList();
      }
      if (_s(body['name']).isEmpty || _s(body['phone']).isEmpty) throw DemoError('Nama dan No. HP wajib diisi.');
      final c = {'id': nid(), 'name': body['name'], 'phone': body['phone'], 'email': body['email'], 'address': body['address']};
      customers.add(c);
      return c;
    }
    final c = need(customers, seg[1], 'Pelanggan');
    if (m == 'PUT') {
      for (final f in ['name', 'phone', 'email', 'address']) {
        if (body.containsKey(f)) c[f] = body[f];
      }
      return c;
    }
    if (m == 'DELETE') {
      final vs = vehicles.where((v) => v['customerId'] == c['id']).map((v) => v['id']).toList();
      services.removeWhere((s) => vs.contains(s['vehicleId']));
      vehicles.removeWhere((v) => v['customerId'] == c['id']);
      customers.remove(c);
      return {'message': 'Pelanggan berhasil dihapus.'};
    }
    final vs = vehicles.where((v) => v['customerId'] == c['id']).toList();
    final ids = vs.map((v) => v['id']).toList();
    final hist = services.where((s) => ids.contains(s['vehicleId'])).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
    return {...c, 'vehicles': vs.map((v) => {...v, 'vehicleModel': by(models, v['vehicleModelId'])}).toList(), 'serviceHistory': hist.map((s) => svcView(s)).toList()};
  }

  dynamic _vehicles(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') return vehicles.map(vehView).toList().reversed.toList();
      if (body['customerId'] == null || body['vehicleModelId'] == null || _s(body['plateNumber']).isEmpty) throw DemoError('Pemilik, jenis kendaraan, dan no. plat wajib diisi.');
      if (vehicles.any((v) => _s(v['plateNumber']).toUpperCase() == _s(body['plateNumber']).toUpperCase())) throw DemoError('Unique constraint: No. plat sudah terdaftar.');
      final v = <String, dynamic>{
        'id': nid(), 'customerId': _int(body['customerId']), 'vehicleModelId': _int(body['vehicleModelId']), 'plateNumber': body['plateNumber'],
        'vin': body['vin'], 'engineNumber': body['engineNumber'], 'color': body['color'], 'purchaseYear': body['purchaseYear'], 'note': body['note'],
      };
      vehicles.add(v);
      return v;
    }
    final v = need(vehicles, seg[1], 'Kendaraan');
    if (m == 'PUT') {
      for (final f in ['customerId', 'vehicleModelId', 'plateNumber', 'vin', 'engineNumber', 'color', 'purchaseYear', 'note']) {
        if (body.containsKey(f)) v[f] = body[f];
      }
      return v;
    }
    if (m == 'DELETE') {
      services.removeWhere((s) => s['vehicleId'] == v['id']);
      vehicles.remove(v);
      return {'message': 'Kendaraan berhasil dihapus.'};
    }
    final hist = services.where((s) => s['vehicleId'] == v['id']).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
    return {...vehView(v), 'services': hist.map((s) => svcView(s)).toList()};
  }

  // ------------------------------------------------------------------ technicians
  dynamic _techs(String m, List<String> seg, _M q, _M body) {
    if (seg.length == 1) {
      if (m == 'GET') {
        var list = techs;
        if (q['activeOnly'] == 'true') list = list.where((t) => t['status'] == 'AKTIF').toList();
        return list
            .map((t) => {...t, '_count': {'services': services.where((s) => s['technicianId'] == t['id']).length, 'schedules': schedules.where((x) => x['technicianId'] == t['id']).length}})
            .toList();
      }
      if (_s(body['name']).isEmpty) throw DemoError('Nama teknisi wajib diisi.');
      final t = {'id': nid(), 'name': body['name'], 'skill': body['skill'], 'status': body['status'] ?? 'AKTIF'};
      techs.add(t);
      return t;
    }
    final t = need(techs, seg[1], 'Teknisi');
    if (seg.length > 2 && seg[2] == 'schedules') {
      if (m == 'POST') {
        final sc = {'id': nid(), 'technicianId': t['id'], 'date': body['date'], 'note': body['note']};
        schedules.add(sc);
        return sc;
      }
      final sc = need(schedules, seg[3], 'Jadwal');
      if (m == 'PUT') {
        sc['date'] = body['date'];
        sc['note'] = body['note'];
        return sc;
      }
      schedules.remove(sc);
      return {'message': 'Jadwal berhasil dihapus.'};
    }
    if (m == 'PUT') {
      for (final f in ['name', 'skill', 'status']) {
        if (body.containsKey(f)) t[f] = body[f];
      }
      return t;
    }
    if (m == 'DELETE') {
      if (services.any((s) => s['technicianId'] == t['id'])) throw DemoError('Teknisi masih punya data service.');
      techs.remove(t);
      return {'message': 'Teknisi berhasil dihapus.'};
    }
    final sch = schedules.where((x) => x['technicianId'] == t['id']).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
    final svs = services.where((s) => s['technicianId'] == t['id']).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
    return {...t, 'schedules': sch, 'services': svs.map((s) => svcView(s)).toList()};
  }

  // ------------------------------------------------------------------ reports
  dynamic _reports(String kind, _M q) {
    final from = DateTime.tryParse(_s(q['from']));
    final to = DateTime.tryParse(_s(q['to']));
    bool ok(dynamic iso) {
      final d = DateTime.parse(_s(iso));
      if (from != null && d.isBefore(from)) return false;
      if (to != null && d.isAfter(to)) return false;
      return true;
    }

    final custId = q['customerId'] == null || _s(q['customerId']).isEmpty ? null : _int(q['customerId']);
    if (kind == 'service') {
      final list = services.where((s) => ok(s['date']) && (custId == null || by(vehicles, s['vehicleId'])?['customerId'] == custId)).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
      num total = 0;
      for (final s in list) {
        total += _num(s['total']);
      }
      // Layanan paling laris: jumlah dipakai & total biaya jasa per nama layanan (sama dengan server)
      final svcMap = <String, _M>{};
      for (final sv in list) {
        for (final d in (sv['details'] as List)) {
          final name = _s(d['name']).trim();
          if (name.isEmpty) continue;
          final row = svcMap.putIfAbsent(name.toLowerCase(), () => {'name': name, 'count': 0, 'revenue': 0});
          row['count'] = _int(row['count']) + 1;
          row['revenue'] = _num(row['revenue']) + _num(d['cost']);
        }
      }
      final top = svcMap.values.toList()
        ..sort((a, b) {
          final c = _int(b['count']).compareTo(_int(a['count']));
          return c != 0 ? c : _num(b['revenue']).compareTo(_num(a['revenue']));
        });
      return {
        'summary': {'totalService': list.length, 'totalBiaya': total, 'selesai': list.where((s) => s['status'] == 'SELESAI').length, 'berjalan': list.where((s) => s['status'] != 'SELESAI').length},
        'topServices': [for (var i = 0; i < top.length; i++) {'rank': i + 1, ...top[i]}],
        'detail': list.map((s) => svcView(s)).toList(),
      };
    }
    if (kind == 'sales') {
      final list = sales.where((s) => ok(s['date']) && (custId == null || s['customerId'] == custId)).toList()..sort((a, b) => _s(b['date']).compareTo(_s(a['date'])));
      num total = 0, laba = 0;
      int items = 0;
      for (final s in list) {
        total += _num(s['total']);
        for (final it in (s['items'] as List)) {
          laba += (_num(it['price']) - _num(by(parts, it['sparepartId'])!['buyPrice'])) * _int(it['qty']);
          items += _int(it['qty']);
        }
      }
      return {
        'summary': {'totalPenjualan': total, 'totalLaba': laba, 'jumlahTransaksi': list.length, 'jumlahItem': items},
        'detail': list.map(saleView).toList(),
      };
    }
    final source = ['SERVICE', 'SALES'].contains(_s(q['source'])) ? _s(q['source']) : 'ALL';
    if (kind == 'sparepart') {
      // Sparepart paling laris dari pemakaian service + penjualan
      final map = <int, _M>{};
      _M bucket(_M sp) => map.putIfAbsent(
            _int(sp['id']),
            () => {
              'id': sp['id'],
              'code': sp['code'],
              'name': sp['name'],
              'category': by(categories, sp['categoryId'])?['name'] ?? '-',
              'qtyService': 0,
              'qtySales': 0,
              'qtyTotal': 0,
              'revenue': 0,
              'profit': 0,
            },
          );
      void add(_M sp, int qty, num price, String qtyKey) {
        final row = bucket(sp);
        row[qtyKey] = _int(row[qtyKey]) + qty;
        row['qtyTotal'] = _int(row['qtyTotal']) + qty;
        row['revenue'] = _num(row['revenue']) + price * qty;
        row['profit'] = _num(row['profit']) + (price - _num(sp['buyPrice'])) * qty;
      }

      if (source != 'SALES') {
        for (final sv in services.where((x) => ok(x['date']))) {
          for (final u in (sv['parts'] as List)) {
            final sp = by(parts, u['sparepartId']);
            if (sp != null) add(sp, _int(u['qty']), _num(u['price']), 'qtyService');
          }
        }
      }
      if (source != 'SERVICE') {
        for (final sl in sales.where((x) => ok(x['date']))) {
          for (final it in (sl['items'] as List)) {
            final sp = by(parts, it['sparepartId']);
            if (sp != null) add(sp, _int(it['qty']), _num(it['price']), 'qtySales');
          }
        }
      }
      final rows = map.values.toList()
        ..sort((a, b) {
          final c = _int(b['qtyTotal']).compareTo(_int(a['qtyTotal']));
          return c != 0 ? c : _num(b['revenue']).compareTo(_num(a['revenue']));
        });
      final detail = [for (var i = 0; i < rows.length; i++) {'rank': i + 1, ...rows[i]}];
      num qtySum = 0, valueSum = 0;
      for (final d in detail) {
        qtySum += _int(d['qtyTotal']);
        valueSum += _num(d['revenue']);
      }
      return {
        'source': source,
        'summary': {'jenisTerjual': detail.length, 'totalQty': qtySum, 'totalNilai': valueSum, 'terlaris': detail.isNotEmpty ? detail.first['name'] : '-'},
        'detail': detail,
      };
    }
    if (kind == 'loyalty') {
      // Pelanggan setia: service LUNAS + penjualan atas nama pelanggan terdaftar
      const activeDays = 90;
      final map = <int, _M>{};
      final firstAt = <int, DateTime>{};
      final lastAt = <int, DateTime>{};
      _M row(int id) => map.putIfAbsent(id, () => {'customerId': id, 'serviceCount': 0, 'salesCount': 0, 'totalSpent': 0});
      void touch(int id, dynamic iso, num total, String countKey) {
        final r = row(id);
        r[countKey] = _int(r[countKey]) + 1;
        r['totalSpent'] = _num(r['totalSpent']) + total;
        final d = DateTime.parse(_s(iso));
        if (firstAt[id] == null || d.isBefore(firstAt[id]!)) firstAt[id] = d;
        if (lastAt[id] == null || d.isAfter(lastAt[id]!)) lastAt[id] = d;
      }

      if (source != 'SALES') {
        for (final sv in services.where((x) => ok(x['date']) && x['status'] == 'SELESAI')) {
          final cid = by(vehicles, sv['vehicleId'])?['customerId'];
          if (cid != null) touch(_int(cid), sv['date'], _num(sv['total']), 'serviceCount');
        }
      }
      if (source != 'SERVICE') {
        for (final sl in sales.where((x) => ok(x['date']) && x['customerId'] != null)) {
          touch(_int(sl['customerId']), sl['date'], _num(sl['total']), 'salesCount');
        }
      }
      final detail = <_M>[];
      for (final r in map.values) {
        final id = _int(r['customerId']);
        final c = by(customers, id);
        final days = DateTime.now().difference(lastAt[id]!).inDays;
        detail.add({
          ...r,
          'name': c?['name'] ?? '-',
          'phone': c?['phone'] ?? '-',
          'visits': _int(r['serviceCount']) + _int(r['salesCount']),
          'firstDate': _iso(firstAt[id]!),
          'lastDate': _iso(lastAt[id]!),
          'daysSince': days,
          'active': days <= activeDays,
        });
      }
      detail.sort((a, b) {
        final c = _int(b['visits']).compareTo(_int(a['visits']));
        return c != 0 ? c : _num(b['totalSpent']).compareTo(_num(a['totalSpent']));
      });
      for (var i = 0; i < detail.length; i++) {
        detail[i]['rank'] = i + 1;
      }
      var visitSum = 0;
      num spentSum = 0;
      for (final d in detail) {
        visitSum += _int(d['visits']);
        spentSum += _num(d['totalSpent']);
      }
      return {
        'source': source,
        'activeDays': activeDays,
        'summary': {
          'totalPelanggan': detail.length,
          'totalTransaksi': visitSum,
          'rataTransaksi': detail.isEmpty ? 0 : (visitSum / detail.length * 10).round() / 10,
          'totalBelanja': spentSum,
        },
        'detail': detail,
      };
    }
    final catId = q['categoryId'] == null || _s(q['categoryId']).isEmpty ? null : _int(q['categoryId']);
    final list = parts.where((p) => catId == null || p['categoryId'] == catId).map(spView).toList();
    num value = 0;
    for (final p in list) {
      value += _num(p['buyPrice']) * _int(p['stock']);
    }
    return {
      'summary': {
        'totalItems': list.length,
        'totalStockValue': value,
        'baik': list.where((p) => p['status'] == 'BAIK').length,
        'rendah': list.where((p) => p['status'] == 'RENDAH').length,
        'habis': list.where((p) => p['status'] == 'HABIS').length,
      },
      'detail': list,
    };
  }
}
