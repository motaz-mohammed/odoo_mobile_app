import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/data/customer_invoice.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class CustomerInvoicesScreen extends StatefulWidget {
  const CustomerInvoicesScreen({super.key});

  @override
  State<CustomerInvoicesScreen> createState() => _CustomerInvoicesScreenState();
}

class _CustomerInvoicesScreenState extends State<CustomerInvoicesScreen> {
  String? _selectedFilter; // null = All, 'not_paid', 'paid'
  late Future<List<CustomerInvoice>> _future;
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<OdooRepository>().fetchCustomerInvoices(paymentState: _selectedFilter);
  }

  Future<void> _showPayDialog(CustomerInvoice inv) async {
    final ctrl = TextEditingController(text: inv.amountResidual.toStringAsFixed(2));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Register Payment • ${inv.name}"),
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
      try {
        final res = await context.read<OdooRepository>().registerInvoicePayment(inv.id, amt);
        AppToast.show(res['message'] ?? "Payment recorded");
        setState(_reload);
      } catch (e) {
        AppToast.showError(e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Invoices"),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                _filterChip("All", null),
                const SizedBox(width: 8),
                _filterChip("Unpaid", "not_paid"),
                const SizedBox(width: 8),
                _filterChip("Paid", "paid"),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CustomerInvoice>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerCardSkeleton();
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text("No customer invoices found."));
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(_reload),
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final inv = items[i];
                      final isPaid = inv.paymentState == 'paid';
                      return SoftShadowCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          title: Text(
                            "${inv.name} • ${inv.customerName}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Date: ${inv.invoiceDate} • Due: ${inv.dueDate}\n"
                            "Total: ${_fmt.format(inv.amountTotal)} | Due: ${_fmt.format(inv.amountResidual)}",
                          ),
                          trailing: isPaid
                              ? const Chip(
                                  label: Text(
                                    "PAID",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  backgroundColor: Color(0xFFE8F5E9),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showPayDialog(inv),
                                  child: const Text("Pay"),
                                ),

                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              Routes.customerInvoiceDetailsScreen,
                              arguments: inv.id,
                            );
                            if (mounted) setState(_reload);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Invoice"),
        onPressed: () async {
          final created = await Navigator.pushNamed(context, Routes.customerInvoiceNewScreen);
          if (created == true && mounted) setState(_reload);
        },
      ),
    );
  }

  Widget _filterChip(String label, String? stateVal) {
    final selected = _selectedFilter == stateVal;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _selectedFilter = stateVal;
        _reload();
      }),
    );
  }
}
