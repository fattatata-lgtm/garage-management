import 'package:flutter/material.dart';

/// Navigator utama (dipakai untuk menutup semua halaman saat sesi berakhir).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Kontrol tab Bottom Bar dari mana saja (mis. dari Dashboard).
class AppNav {
  AppNav._();
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static final ValueNotifier<String> serviceFilter = ValueNotifier<String>('ALL');
  static final ValueNotifier<String> stockFilter = ValueNotifier<String>('ALL');

  static void openServices([String filter = 'ALL']) {
    serviceFilter.value = filter;
    tab.value = 1;
  }

  static void openStock([String filter = 'ALL']) {
    stockFilter.value = filter;
    tab.value = 3;
  }
}

/// Dinaikkan setiap ada perubahan data (simpan/hapus) agar semua daftar & dashboard memuat ulang.
class Bus {
  Bus._();
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
  static void bump() => tick.value++;
}

/// Pindah halaman penuh (menutupi bottom bar).
Future<T?> go<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));
}
