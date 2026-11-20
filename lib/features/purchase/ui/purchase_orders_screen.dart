import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/purchase_summary.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  late Future<List<PurchaseSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OdooRepository>().fetchPurchaseOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Orders"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = context.read<OdooRepository>().fetchPurchaseOrders()),
          ),
        ],
      ),
      body: FutureBuilder<List<PurchaseSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const ShimmerCardSkeleton();
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text("No purchase orders found."));

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.table_view),
                  label: const Text("Export Purchase Orders to Excel (.xlsx)"),
                  onPressed: () => ReportExportService.exportPurchasesExcel(list),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final po = list[i];
                    return SoftShadowCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                        title: Text(po.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${po.vendorName}\n${po.dateOrder}"),
                        trailing: Text(
                          po.amountTotal.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
