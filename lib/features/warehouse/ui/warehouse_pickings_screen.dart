import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/warehouse_picking.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class WarehousePickingsScreen extends StatelessWidget {
  const WarehousePickingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Warehouse Operations"),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: "Deliveries (Zone)"),
              Tab(icon: Icon(Icons.move_to_inbox), text: "Receipts (Incoming)"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PickingListTab(type: 'outgoing'),
            _PickingListTab(type: 'incoming'),
          ],
        ),
      ),
    );
  }
}

class _PickingListTab extends StatefulWidget {
  final String type;
  const _PickingListTab({required this.type});

  @override
  State<_PickingListTab> createState() => _PickingListTabState();
}

class _PickingListTabState extends State<_PickingListTab> {
  late Future<List<WarehousePicking>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OdooRepository>().fetchWarehousePickings(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WarehousePicking>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const ShimmerCardSkeleton();
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const Center(child: Text("No transfers pending."));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final p = list[i];
            return SoftShadowCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: p.state == 'done' ? Colors.green : Colors.orange,
                  child: const Icon(Icons.inventory, color: Colors.white),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${p.partnerName} • Origin: ${p.origin}\n${p.scheduledDate}"),
                trailing: Chip(label: Text(p.state.toUpperCase())),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    Routes.warehousePickingDetailsScreen,
                    arguments: p.id,
                  );
                  if (mounted) {
                    setState(
                      () => _future = context.read<OdooRepository>().fetchWarehousePickings(
                        widget.type,
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
