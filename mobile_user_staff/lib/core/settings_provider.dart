import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import 'api_client.dart';
import 'config.dart';
import 'storage.dart';

/// Identitas bengkel & pajak (dari /settings). Sebelum login hanya nama & logo.
class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = Store.themeMode;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await Store.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  String businessName = AppConfig.appName;
  String? logoUrl;
  String? address;
  String? phone;
  num taxService = 10;
  num taxSales = 10;
  String? printerType; // "Thermal 58mm" / "Thermal 80mm"
  String? printerConnection; // BROWSER | SYSTEM | NETWORK | USB | SERIAL | BLUETOOTH

  String get logo => Store.asset(logoUrl);

  Future<void> load({required bool authed}) async {
    try {
      final d = await Api.I.get(authed ? '/settings' : '/settings/public');
      if (d is! Map) return;
      businessName = (d['businessName'] as String?)?.trim().isNotEmpty == true
          ? d['businessName'] as String
          : AppConfig.appName;
      logoUrl = d['logoUrl'] as String?;
      if (authed) {
        address = d['address'] as String?;
        phone = d['phone'] as String?;
        taxService = num.tryParse('${d['taxService']}') ?? 10;
        taxSales = num.tryParse('${d['taxSales']}') ?? 10;
        printerType = d['printerType'] as String?;
        printerConnection = d['printerConnection'] as String?;
      }
      notifyListeners();
    } catch (_) {
      // abaikan: aplikasi tetap jalan dengan nilai bawaan
    }
  }
}
