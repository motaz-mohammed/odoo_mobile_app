// sales_quotation_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';
import 'package:odoo_mobile_app/features/sales_quotation_details_screen/logic/sales_quotation_details_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_details_screen/logic/sales_quotation_details_state.dart';

class SalesQuotationDetails extends StatelessWidget {
  const SalesQuotationDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<SalesQuotationDetailsCubit, SalesQuotationDetailsState>(
            builder: (context, state) {
              if (state is SalesQuotationDetailsLoaded) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Print Order PDF",
                      icon: const Icon(Icons.print),
                      onPressed: () => ReportExportService.printOrShareOrderPdf(state.order),
                    ),
                    IconButton(
                      tooltip: "Share Order PDF to Apps",
                      icon: const Icon(Icons.share),
                      onPressed: () => ReportExportService.shareOrderPdfToApps(state.order),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesQuotationDetailsCubit, SalesQuotationDetailsState>(
        builder: (context, state) {
          if (state is SalesQuotationDetailsLoading) return const ShimmerCardSkeleton();
          if (state is SalesQuotationDetailsError) return Center(child: Text(state.errorMessage));
          if (state is SalesQuotationDetailsLoaded) {
            final order = state.order;
            return Column(
              children: [
                SoftShadowCard(
                  child: ListTile(
                    title: Text(
                      order.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text("${order.date} • Items: ${order.lines.length}"),
                    trailing: Chip(label: Text(order.state.toUpperCase())),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: order.lines.length,
                    itemBuilder: (_, i) {
                      final line = order.lines[i];
                      return SoftShadowCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: _productThumb(line.imageBase64),
                          title: Text(
                            line.product,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Qty: ${line.quantity} x ${line.price}"),
                          trailing: Text(
                            line.subtotal.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
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

  Widget _productThumb(String? b64) {
    if (b64 == null || b64.isEmpty)
      return const Icon(Icons.inventory_2, size: 36, color: Colors.grey);
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(base64Decode(b64), width: 44, height: 44, fit: BoxFit.cover),
      );
    } catch (_) {
      return const Icon(Icons.broken_image, size: 36, color: Colors.grey);
    }
  }
}
