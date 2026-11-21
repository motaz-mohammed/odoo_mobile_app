import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/data/purchase_detail.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class PurchaseOrderDetailsScreen extends StatefulWidget {
  final int poId;
  const PurchaseOrderDetailsScreen({super.key, required this.poId});

  @override
  State<PurchaseOrderDetailsScreen> createState() => _PurchaseOrderDetailsScreenState();
}

class _PurchaseOrderDetailsScreenState extends State<PurchaseOrderDetailsScreen> {
  late Future<PurchaseDetail> _future;
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    _future = context.read<OdooRepository>().fetchPurchaseOrderDetail(widget.poId);
  }

  Future<void> _handleConfirmRfq() async {
    setState(() => _isConfirming = true);
    try {
      final result = await context.read<OdooRepository>().confirmPurchaseOrder(widget.poId);
      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'RFQ confirmed to Purchase Order'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _loadOrderDetails();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to confirm RFQ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PurchaseDetail>(
      future: _future,
      builder: (context, snapshot) {
        final po = snapshot.data;
        final canConfirm = po != null && (po.orderState == 'draft' || po.orderState == 'sent');

        return Scaffold(
          appBar: AppBar(
            title: Text(po?.poName ?? "Purchase Order Details"),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            actions: [
              if (po != null)
                IconButton(
                  tooltip: "Print / Share PDF",
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => ReportExportService.printPurchaseOrderPdf(po),
                ),
            ],
          ),
          body: Builder(
            builder: (_) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ShimmerCardSkeleton();
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (po == null) {
                return const Center(child: Text("Purchase order not found."));
              }

              return Column(
                children: [
                  SoftShadowCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                po.vendorName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              label: Text(po.orderState.toUpperCase()),
                              backgroundColor: Colors.deepPurple.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Order Date: ${po.orderDate}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Untaxed: ${_fmt.format(po.amountUntaxed)}"),
                            Text("Tax: ${_fmt.format(po.amountTax)}"),
                            Text(
                              "Total: ${_fmt.format(po.amountTotal)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: po.lines.length,
                      itemBuilder: (_, i) {
                        final line = po.lines[i];
                        return SoftShadowCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: _productThumb(line.imageBase64),
                            title: Text(
                              line.product,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Ordered: ${line.quantity} ${line.uom} • Received: ${line.qtyReceived}\n"
                              "Unit Price: ${_fmt.format(line.priceUnit)}",
                            ),
                            trailing: Text(
                              _fmt.format(line.subtotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
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
          bottomNavigationBar: canConfirm
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isConfirming ? null : _handleConfirmRfq,
                        icon: _isConfirming
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isConfirming ? 'Confirming...' : 'Confirm RFQ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _productThumb(String? b64) {
    if (b64 == null || b64.isEmpty) {
      return const Icon(Icons.inventory_2, size: 36, color: Colors.grey);
    }
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
