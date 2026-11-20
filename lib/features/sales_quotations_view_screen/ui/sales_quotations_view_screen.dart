import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';
import 'package:odoo_mobile_app/features/sales_quotations_view_screen/logic/cubits/sales_quotation_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotations_view_screen/logic/cubits/sales_quotation_state.dart';

class SalesQuotationsView extends StatefulWidget {
  const SalesQuotationsView({super.key});

  @override
  State<SalesQuotationsView> createState() => _SalesQuotationsViewState();
}

class _SalesQuotationsViewState extends State<SalesQuotationsView> {
  String _search = "";
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Quotations & Orders"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<SalesQuotationCubit, SalesQuotationState>(
            builder: (context, state) {
              if (state is SalesQuotationLoaded && state.orders.isNotEmpty) {
                return IconButton(
                  tooltip: "Export Excel (.xlsx)",
                  icon: const Icon(Icons.table_view),
                  onPressed: () => ReportExportService.exportSalesExcel(state.orders),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<SalesQuotationCubit>().getQuotations(),
          ),
        ],
      ),
      body: BlocBuilder<SalesQuotationCubit, SalesQuotationState>(
        builder: (context, state) {
          if (state is SalesQuotationLoading) {
            return const ShimmerCardSkeleton();
          }
          if (state is SalesQuotationError) {
            return Center(child: Text(state.errorMessage));
          }
          if (state is SalesQuotationLoaded) {
            final filtered = state.orders
                .where((o) =>
                    o.name.toLowerCase().contains(_search.toLowerCase()) ||
                    o.partnerName.toLowerCase().contains(_search.toLowerCase()))
                .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search order or customer...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final o = filtered[i];
                      return SoftShadowCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                          title: Text(o.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${o.partnerName}\n${o.dateOrder}"),
                          trailing: Text(
                            _fmt.format(o.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.salesQuotationDetails,
                            arguments: o.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
