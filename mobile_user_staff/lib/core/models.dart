// Model data - dipetakan dari respons REST API backend (Prisma).
// Kolom Decimal dikirim backend sebagai string, jadi selalu lewat helper _n.

num _n(dynamic v) {
  if (v is num) return v;
  return num.tryParse('${v ?? ''}') ?? 0;
}

int _i(dynamic v) => _n(v).toInt();
String _s(dynamic v) => v?.toString() ?? '';
String? _sn(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
Map<String, dynamic>? _m(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<T> _l<T>(dynamic v, T Function(Map<String, dynamic>) f) {
  if (v is! List) return <T>[];
  return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
}

T? _o<T>(dynamic v, T Function(Map<String, dynamic>) f) {
  final m = _m(v);
  return m == null ? null : f(m);
}

// ---------------------------------------------------------------- Pelanggan

class Customer {
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.vehicleCount = 0,
    this.vehicles = const [],
    this.serviceHistory = const [],
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final int vehicleCount;
  final List<Vehicle> vehicles;
  final List<Service> serviceHistory;

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: _i(j['id']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        email: _sn(j['email']),
        address: _sn(j['address']),
        vehicleCount: _i(_m(j['_count'])?['vehicles']),
        vehicles: _l(j['vehicles'], Vehicle.fromJson),
        serviceHistory: _l(j['serviceHistory'], Service.fromJson),
      );
}

// ---------------------------------------------------------------- Kendaraan

class VehicleModel {
  VehicleModel({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.type,
    required this.wheels,
  });

  final int id;
  final String brand;
  final String model;
  final int year;
  final String type;
  final int wheels;

  String get label => '$brand $model';
  bool get isMotor => wheels == 2;

  factory VehicleModel.fromJson(Map<String, dynamic> j) => VehicleModel(
        id: _i(j['id']),
        brand: _s(j['brand']),
        model: _s(j['model']),
        year: _i(j['year']),
        type: _s(j['type']),
        wheels: j['wheels'] == null ? 4 : _i(j['wheels']),
      );
}

class Vehicle {
  Vehicle({
    required this.id,
    required this.customerId,
    required this.vehicleModelId,
    required this.plateNumber,
    this.vin,
    this.engineNumber,
    this.color,
    this.purchaseYear,
    this.note,
    this.customer,
    this.model,
    this.services = const [],
  });

  final int id;
  final int customerId;
  final int vehicleModelId;
  final String plateNumber;
  final String? vin;
  final String? engineNumber;
  final String? color;
  final int? purchaseYear;
  final String? note;
  final Customer? customer;
  final VehicleModel? model;
  final List<Service> services;

  String get modelLabel => model?.label ?? 'Kendaraan';
  bool get isMotor => model?.isMotor ?? false;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: _i(j['id']),
        customerId: _i(j['customerId']),
        vehicleModelId: _i(j['vehicleModelId']),
        plateNumber: _s(j['plateNumber']),
        vin: _sn(j['vin']),
        engineNumber: _sn(j['engineNumber']),
        color: _sn(j['color']),
        purchaseYear: j['purchaseYear'] == null ? null : _i(j['purchaseYear']),
        note: _sn(j['note']),
        customer: _o(j['customer'], Customer.fromJson),
        model: _o(j['vehicleModel'], VehicleModel.fromJson),
        services: _l(j['services'], Service.fromJson),
      );
}

// ---------------------------------------------------------------- Sparepart

class Category {
  Category({required this.id, required this.name, this.count = 0});
  final int id;
  final String name;
  final int count;

  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: _i(j['id']), name: _s(j['name']), count: _i(_m(j['_count'])?['spareparts']));
}

/// Pemasok sparepart (sama dengan menu Supplier di website).
class Supplier {
  Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.note,
    this.sparepartCount = 0,
  });

  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? note;
  final int sparepartCount;

  factory Supplier.fromJson(Map<String, dynamic> j) => Supplier(
        id: _i(j['id']),
        name: _s(j['name']),
        contactPerson: _sn(j['contactPerson']),
        phone: _sn(j['phone']),
        email: _sn(j['email']),
        address: _sn(j['address']),
        note: _sn(j['note']),
        sparepartCount: _i(_m(j['_count'])?['spareparts']),
      );
}

class StockHistory {
  StockHistory({
    required this.id,
    required this.direction,
    required this.source,
    required this.quantity,
    this.note,
    this.refInvoice,
    this.createdAt,
    this.sparepartName,
    this.supplierName,
  });

  final int id;
  final String direction; // MASUK | KELUAR
  final String source; // MANUAL | SERVICE | PENJUALAN
  final int quantity;
  final String? note;
  final String? refInvoice;
  final DateTime? createdAt;
  final String? sparepartName;
  final String? supplierName; // supplier asal barang (stok MASUK manual, opsional)

  bool get masuk => direction == 'MASUK';

  factory StockHistory.fromJson(Map<String, dynamic> j) => StockHistory(
        id: _i(j['id']),
        direction: _s(j['direction']),
        source: _s(j['source']),
        quantity: _i(j['quantity']),
        note: _sn(j['note']),
        refInvoice: _sn(j['refInvoice']),
        createdAt: _dt(j['createdAt']),
        sparepartName: _sn(_m(j['sparepart'])?['name']),
        supplierName: _sn(_m(j['supplier'])?['name']),
      );
}

class Sparepart {
  Sparepart({
    required this.id,
    required this.code,
    required this.name,
    required this.categoryId,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.lowStockThreshold,
    required this.status,
    this.category,
    this.supplierId,
    this.supplier,
    this.history = const [],
  });

  final int id;
  final String code;
  final String name;
  final int categoryId;
  final num buyPrice;
  final num sellPrice;
  final int stock;
  final int lowStockThreshold;
  final String status; // BAIK | RENDAH | HABIS
  final Category? category;
  final int? supplierId;
  final Supplier? supplier;
  final List<StockHistory> history;

  String get categoryName => category?.name ?? '-';
  String? get supplierName => supplier?.name;

  factory Sparepart.fromJson(Map<String, dynamic> j) {
    final stock = _i(j['stock']);
    final low = j['lowStockThreshold'] == null ? 5 : _i(j['lowStockThreshold']);
    final computed = stock <= 0 ? 'HABIS' : (stock <= low ? 'RENDAH' : 'BAIK');
    return Sparepart(
      id: _i(j['id']),
      code: _s(j['code']),
      name: _s(j['name']),
      categoryId: _i(j['categoryId']),
      buyPrice: _n(j['buyPrice']),
      sellPrice: _n(j['sellPrice']),
      stock: stock,
      lowStockThreshold: low,
      status: _sn(j['status']) ?? computed,
      category: _o(j['category'], Category.fromJson),
      supplierId: j['supplierId'] == null ? null : _i(j['supplierId']),
      supplier: _o(j['supplier'], Supplier.fromJson),
      history: _l(j['stockHistory'], StockHistory.fromJson),
    );
  }
}

// ---------------------------------------------------------------- Teknisi

class Schedule {
  Schedule({required this.id, required this.date, this.note});
  final int id;
  final DateTime? date;
  final String? note;

  factory Schedule.fromJson(Map<String, dynamic> j) =>
      Schedule(id: _i(j['id']), date: _dt(j['date']), note: _sn(j['note']));
}

class Technician {
  Technician({
    required this.id,
    required this.name,
    this.skill,
    required this.status,
    this.serviceCount = 0,
    this.scheduleCount = 0,
    this.schedules = const [],
    this.services = const [],
  });

  final int id;
  final String name;
  final String? skill;
  final String status; // AKTIF | NONAKTIF
  final int serviceCount;
  final int scheduleCount;
  final List<Schedule> schedules;
  final List<Service> services;

  bool get aktif => status == 'AKTIF';

  factory Technician.fromJson(Map<String, dynamic> j) {
    final count = _m(j['_count']);
    final schedules = _l(j['schedules'], Schedule.fromJson);
    final services = _l(j['services'], Service.fromJson);
    return Technician(
      id: _i(j['id']),
      name: _s(j['name']),
      skill: _sn(j['skill']),
      status: _sn(j['status']) ?? 'AKTIF',
      serviceCount: count != null ? _i(count['services']) : services.length,
      scheduleCount: count != null ? _i(count['schedules']) : schedules.length,
      schedules: schedules,
      services: services,
    );
  }
}

// ---------------------------------------------------------------- Master layanan & diskon

class ServiceType {
  ServiceType({required this.id, required this.name, this.description, required this.estimatedCost});
  final int id;
  final String name;
  final String? description;
  final num estimatedCost;

  factory ServiceType.fromJson(Map<String, dynamic> j) => ServiceType(
        id: _i(j['id']),
        name: _s(j['name']),
        description: _sn(j['description']),
        estimatedCost: _n(j['estimatedCost']),
      );
}

class Discount {
  Discount({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    required this.value,
    required this.scope,
    required this.status,
  });

  final int id;
  final String name;
  final String? code;
  final String type; // PERCENTAGE | NOMINAL
  final num value;
  final String scope; // SEMUA | SERVICE | SPAREPART
  final String status;

  num amountFor(num subtotal) => type == 'PERCENTAGE' ? subtotal * value / 100 : value;

  String get valueLabel => type == 'PERCENTAGE' ? '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%' : 'Rp${value.round()}';

  factory Discount.fromJson(Map<String, dynamic> j) => Discount(
        id: _i(j['id']),
        name: _s(j['name']),
        code: _sn(j['code']),
        type: _s(j['type']),
        value: _n(j['value']),
        scope: _sn(j['scope']) ?? 'SEMUA',
        status: _sn(j['status']) ?? 'AKTIF',
      );
}

// ---------------------------------------------------------------- Service

class ServiceDetail {
  ServiceDetail({required this.name, this.description, required this.cost});
  final String name;
  final String? description;
  final num cost;

  factory ServiceDetail.fromJson(Map<String, dynamic> j) =>
      ServiceDetail(name: _s(j['name']), description: _sn(j['description']), cost: _n(j['cost']));
}

class ServicePart {
  ServicePart({
    required this.sparepartId,
    required this.name,
    required this.code,
    required this.qty,
    required this.price,
    required this.stock,
  });

  final int sparepartId;
  final String name;
  final String code;
  final int qty;
  final num price;
  final int stock; // stok sparepart saat ini (di luar pemakaian service ini)

  factory ServicePart.fromJson(Map<String, dynamic> j) {
    final sp = _m(j['sparepart']);
    return ServicePart(
      sparepartId: _i(j['sparepartId']),
      name: _s(sp?['name']),
      code: _s(sp?['code']),
      qty: _i(j['qty']),
      price: _n(j['price']),
      stock: _i(sp?['stock']),
    );
  }
}

class ServiceLog {
  ServiceLog({this.status, required this.title, this.note, this.actor, this.createdAt});
  final String? status;
  final String title;
  final String? note;
  final String? actor;
  final DateTime? createdAt;

  factory ServiceLog.fromJson(Map<String, dynamic> j) => ServiceLog(
        status: _sn(j['status']),
        title: _s(j['title']),
        note: _sn(j['note']),
        actor: _sn(j['actor']),
        createdAt: _dt(j['createdAt']),
      );
}

class Service {
  Service({
    required this.id,
    required this.invoiceNo,
    this.date,
    this.km,
    required this.complaint,
    required this.internalNote,
    required this.status,
    this.discountId,
    this.discount,
    required this.nextRecommendation,
    this.nextDate,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.paid,
    required this.change,
    this.vehicle,
    this.technician,
    this.details = const [],
    this.parts = const [],
    this.logs = const [],
  });

  final int id;
  final String invoiceNo;
  final DateTime? date;
  final int? km;
  final String complaint;
  final String internalNote;
  final String status; // DITERIMA | DIKERJAKAN | MENUNGGU_PEMBAYARAN | SELESAI
  final int? discountId;
  final Discount? discount;
  final String nextRecommendation;
  final DateTime? nextDate;
  final num subtotal;
  final num discountAmount;
  final num taxAmount;
  final num total;
  final num paid;
  final num change;
  final Vehicle? vehicle;
  final Technician? technician;
  final List<ServiceDetail> details;
  final List<ServicePart> parts;
  final List<ServiceLog> logs;

  bool get lunas => status == 'SELESAI';
  String get plate => vehicle?.plateNumber ?? '-';
  String get ownerName => vehicle?.customer?.name ?? '-';
  num get jasaTotal => details.fold<num>(0, (a, d) => a + d.cost);
  num get partsTotal => parts.fold<num>(0, (a, p) => a + p.price * p.qty);

  factory Service.fromJson(Map<String, dynamic> j) => Service(
        id: _i(j['id']),
        invoiceNo: _s(j['invoiceNo']),
        date: _dt(j['date']),
        km: j['km'] == null ? null : _i(j['km']),
        complaint: _s(j['complaint']),
        internalNote: _s(j['internalNote']),
        status: _s(j['status']),
        discountId: j['discountId'] == null ? null : _i(j['discountId']),
        discount: _o(j['discount'], Discount.fromJson),
        nextRecommendation: _s(j['nextServiceRecommendation']),
        nextDate: _dt(j['nextServiceDate']),
        subtotal: _n(j['subtotal']),
        discountAmount: _n(j['discountAmount']),
        taxAmount: _n(j['taxAmount']),
        total: _n(j['total']),
        paid: _n(j['paid']),
        change: _n(j['change']),
        vehicle: _o(j['vehicle'], Vehicle.fromJson),
        technician: _o(j['technician'], Technician.fromJson),
        details: _l(j['details'], ServiceDetail.fromJson),
        parts: _l(j['spareparts'], ServicePart.fromJson),
        logs: _l(j['logs'], ServiceLog.fromJson),
      );
}

// ---------------------------------------------------------------- Penjualan

class SaleItem {
  SaleItem({required this.sparepartId, required this.name, required this.code, required this.qty, required this.price});
  final int sparepartId;
  final String name;
  final String code;
  final int qty;
  final num price;

  factory SaleItem.fromJson(Map<String, dynamic> j) {
    final sp = _m(j['sparepart']);
    return SaleItem(
      sparepartId: _i(j['sparepartId']),
      name: _s(sp?['name']),
      code: _s(sp?['code']),
      qty: _i(j['qty']),
      price: _n(j['price']),
    );
  }
}

class Sale {
  Sale({
    required this.id,
    required this.invoiceNo,
    this.customer,
    this.walkInName,
    this.date,
    this.discount,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    required this.paid,
    required this.change,
    this.items = const [],
  });

  final int id;
  final String invoiceNo;
  final Customer? customer;
  final String? walkInName;
  final DateTime? date;
  final Discount? discount;
  final num subtotal;
  final num discountAmount;
  final num taxAmount;
  final num total;
  final num paid;
  final num change;
  final List<SaleItem> items;

  String get customerName => customer?.name ?? walkInName ?? 'Pelanggan Umum';
  int get itemCount => items.fold<int>(0, (a, i) => a + i.qty);

  factory Sale.fromJson(Map<String, dynamic> j) => Sale(
        id: _i(j['id']),
        invoiceNo: _s(j['invoiceNo']),
        customer: _o(j['customer'], Customer.fromJson),
        walkInName: _sn(j['walkInName']),
        date: _dt(j['date']),
        discount: _o(j['discount'], Discount.fromJson),
        subtotal: _n(j['subtotal']),
        discountAmount: _n(j['discountAmount']),
        taxAmount: _n(j['taxAmount']),
        total: _n(j['total']),
        paid: _n(j['paid']),
        change: _n(j['change']),
        items: _l(j['items'], SaleItem.fromJson),
      );
}

// ---------------------------------------------------------------- Dashboard

class DashboardSummary {
  DashboardSummary({
    required this.totalCustomers,
    required this.totalVehicles,
    required this.totalServices,
    required this.pendapatanService,
    required this.pendapatanSales,
    required this.totalPendapatan,
    required this.labaEstimasi,
    required this.lowStockAlerts,
    required this.recentServices,
  });

  final int totalCustomers;
  final int totalVehicles;
  final int totalServices;
  final num pendapatanService;
  final num pendapatanSales;
  final num totalPendapatan;
  final num labaEstimasi;
  final List<Sparepart> lowStockAlerts;
  final List<Service> recentServices;

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        totalCustomers: _i(j['totalCustomers']),
        totalVehicles: _i(j['totalVehicles']),
        totalServices: _i(j['totalServices']),
        pendapatanService: _n(j['pendapatanService']),
        pendapatanSales: _n(j['pendapatanSales']),
        totalPendapatan: _n(j['totalPendapatan']),
        labaEstimasi: _n(j['labaEstimasi']),
        lowStockAlerts: _l(j['lowStockAlerts'], Sparepart.fromJson),
        recentServices: _l(j['recentServices'], Service.fromJson),
      );
}

// ---------------------------------------------------------------- Baris laporan (Laporan Layanan, Sparepart & Loyalitas)

/// Layanan paling laris (Laporan Layanan -> Tampilan "Layanan Paling Laris").
class TopService {
  TopService({required this.name, required this.count, required this.revenue});
  final String name;
  final int count;
  final num revenue;

  factory TopService.fromJson(Map<String, dynamic> j) =>
      TopService(name: _s(j['name']), count: _i(j['count']), revenue: _n(j['revenue']));
}

/// Sparepart paling laris dari service + penjualan (Laporan Sparepart).
class SparepartSales {
  SparepartSales({
    required this.code,
    required this.name,
    required this.category,
    required this.qtyService,
    required this.qtySales,
    required this.qtyTotal,
    required this.revenue,
    required this.profit,
  });

  final String code;
  final String name;
  final String category;
  final int qtyService;
  final int qtySales;
  final int qtyTotal;
  final num revenue;
  final num profit;

  factory SparepartSales.fromJson(Map<String, dynamic> j) => SparepartSales(
        code: _s(j['code']),
        name: _s(j['name']),
        category: _sn(j['category']) ?? '-',
        qtyService: _i(j['qtyService']),
        qtySales: _i(j['qtySales']),
        qtyTotal: _i(j['qtyTotal']),
        revenue: _n(j['revenue']),
        profit: _n(j['profit']),
      );
}

/// Pelanggan setia (Laporan Loyalitas).
class LoyaltyRow {
  LoyaltyRow({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.serviceCount,
    required this.salesCount,
    required this.visits,
    required this.totalSpent,
    this.lastDate,
    required this.active,
  });

  final int customerId;
  final String name;
  final String phone;
  final int serviceCount;
  final int salesCount;
  final int visits;
  final num totalSpent;
  final DateTime? lastDate;
  final bool active;

  factory LoyaltyRow.fromJson(Map<String, dynamic> j) => LoyaltyRow(
        customerId: _i(j['customerId']),
        name: _s(j['name']),
        phone: _s(j['phone']),
        serviceCount: _i(j['serviceCount']),
        salesCount: _i(j['salesCount']),
        visits: _i(j['visits']),
        totalSpent: _n(j['totalSpent']),
        lastDate: _dt(j['lastDate']),
        active: j['active'] == true,
      );
}
