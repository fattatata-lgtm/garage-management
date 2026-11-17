import 'package:flutter/material.dart';

import '../core/nav.dart';
import 'dashboard_screen.dart';
import 'more/more_screen.dart';
import 'sales/sales_list_screen.dart';
import 'services/service_list_screen.dart';
import 'spareparts/sparepart_list_screen.dart';

/// Kerangka utama aplikasi: Bottom Navigation Bar dengan 5 tab.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final Set<int> _visited = {0}; // tab dibuat saat pertama dikunjungi (hemat memuat data)

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Beranda'),
    NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build_rounded), label: 'Layanan'),
    NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale_rounded), label: 'Penjualan'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2_rounded), label: 'Sparepart'),
    NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Menu'),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ServiceListScreen();
      case 2:
        return const SalesListScreen();
      case 3:
        return const SparepartListScreen();
      default:
        return const MoreScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppNav.tab,
      builder: (context, index, _) {
        _visited.add(index);
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) AppNav.tab.value = 0;
          },
          child: Scaffold(
            body: _TabFade(
              index: index,
              child: IndexedStack(
                index: index,
                children: List.generate(5, (i) => _visited.contains(i) ? _page(i) : const SizedBox.shrink()),
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => AppNav.tab.value = v,
              destinations: _destinations,
            ),
          ),
        );
      },
    );
  }
}

/// Memudar + naik tipis setiap kali tab berganti.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(covariant _TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: 0.35 + 0.65 * _a.value,
        child: Transform.translate(offset: Offset(0, (1 - _a.value) * 10), child: child),
      ),
    );
  }
}
