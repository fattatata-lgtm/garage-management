import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/nav.dart';
import '../../widgets/common.dart';
import '../../widgets/tiles.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _q = '';

  Future<void> _open(Widget page) async {
    await go<dynamic>(context, page);
    Bus.bump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pelanggan')),
      floatingActionButton: FloatingActionButton.extended(heroTag: null, 
        onPressed: () => _open(const CustomerFormScreen()),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Pelanggan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: SearchField(hint: 'Cari nama / no. HP / email...', onChanged: (v) => setState(() => _q = v)),
          ),
          Expanded(
            child: AsyncBody<List<Customer>>(
              refreshOn: Bus.tick,
              loader: () => Api.I.list('/customers', Customer.fromJson),
              builder: (context, all, reload) {
                final q = _q.trim().toLowerCase();
                final list = all.where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q) || (c.email?.toLowerCase().contains(q) ?? false)).toList();
                if (list.isEmpty) return emptyList(Icons.people_outline_rounded, 'Pelanggan tidak ditemukan');
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (context, i) => CustomerTile(customer: list[i], onTap: () => _open(CustomerDetailScreen(id: list[i].id))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
