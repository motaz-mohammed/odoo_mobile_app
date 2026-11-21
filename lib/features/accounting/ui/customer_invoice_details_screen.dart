import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/data/customer_invoice_detail.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class CustomerInvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;
  const CustomerInvoiceDetailsScreen({super.key, required this.invoiceId});

  @override
  State<CustomerInvoiceDetailsScreen> createState() => _CustomerInvoiceDetailsScreenState();
}

class _CustomerInvoiceDetailsScreenState extends State<CustomerInvoiceDetailsScreen> {
  late Future<CustomerInvoiceDetail> _future;
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    _future = context.read<OdooRepository>().fetchCustomerInvoiceDetail(widget.invoiceId);
  }

  Future<void> _showPayDialog(CustomerInvoiceDetail inv) async {
    final ctrl = TextEditingController(text: inv.amountResidual.toStringAsFixed(2));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Register Payment • ${inv.invoiceName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${inv.customerName}"),
            Text("Balance Due: ${_fmt.format(inv.amountResidual)}"),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Payment Amount",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Confirm Payment"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
      if (amt <= 0) {
        AppToast.showError("Enter a valid positive amount.");
        return;
      }
      setState(() => _isPaying = true);
      try {
        final res = await context.read<OdooRepository>().registerInvoicePayment(inv.invoiceId, amt);
        AppToast.show(res['message'] ?? "Payment recorded");
        setState(_loadDetails);
      } catch (e) {
        AppToast.showError(e.toString().replaceAll("Exception: ", ""));
      } finally {
        if (mounted) setState(() => _isPaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerInvoiceDetail>(
      future: _future,
      builder: (context, snapshot) {
        final inv = snapshot.data;
        final canPay = inv != null && inv.paymentState != 'paid' && inv.amountResidual > 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(inv?.invoiceName ?? "Invoice Details"),
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
            actions: [
              if (inv != null) ...[
                IconButton(
                  tooltip: "Print Invoice PDF",
                  icon: const Icon(Icons.print),
                  onPressed: () => ReportExportService.printCustomerInvoicePdf(inv),
                ),
                IconButton(
                  tooltip: "Share Invoice PDF to Apps",
                  icon: const Icon(Icons.share),
                  onPressed: () => ReportExportService.shareCustomerInvoicePdfToApps(inv),
                ),
              ],
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
              if (inv == null) {
                return const Center(child: Text("Customer invoice not found."));
              }

              final isPaid = inv.paymentState == 'paid';

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
                                inv.customerName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              label: Text(
                                inv.paymentState.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPaid ? Colors.green.shade800 : Colors.amber.shade900,
                                ),
                              ),
                              backgroundColor: isPaid ? Colors.green.shade50 : Colors.amber.shade50,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Invoice Date: ${inv.invoiceDate} • Due: ${inv.dueDate}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        if (inv.invoiceOrigin.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              "Source Order: ${inv.invoiceOrigin}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                            ),
                          ),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Untaxed: ${_fmt.format(inv.amountUntaxed)}"),
                            Text("Tax: ${_fmt.format(inv.amountTax)}"),
                            Text(
                              "Total: ${_fmt.format(inv.amountTotal)}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Amount Due: ${_fmt.format(inv.amountResidual)}",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: inv.lines.length,
                      itemBuilder: (_, i) {
                        final line = inv.lines[i];
                        return SoftShadowCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading: _productThumb(line.imageBase64),
                            title: Text(
                              line.product,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Qty: ${line.quantity} ${line.uom} • Unit: ${_fmt.format(line.priceUnit)}"
                              "${line.discount > 0 ? ' (-${line.discount}%)' : ''}",
                            ),
                            trailing: Text(
                              _fmt.format(line.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
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
          bottomNavigationBar: canPay
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isPaying ? null : () => _showPayDialog(inv),
                        icon: _isPaying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.payments_outlined),
                        label: Text(
                          _isPaying
                              ? 'Processing...'
                              : 'Register Payment (${_fmt.format(inv.amountResidual)})',
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
