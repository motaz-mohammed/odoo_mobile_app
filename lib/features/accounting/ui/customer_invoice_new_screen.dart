import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class CustomerInvoiceNewScreen extends StatefulWidget {
  const CustomerInvoiceNewScreen({super.key});

  @override
  State<CustomerInvoiceNewScreen> createState() => _CustomerInvoiceNewScreenState();
}

class _CustomerInvoiceNewScreenState extends State<CustomerInvoiceNewScreen> {
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  int? _selectedCustomerId;
  bool _autoPost = true;
  bool _isLoadingData = true;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _cartLines = [];
  final _fmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    try {
      final repo = context.read<OdooRepository>();
      // Uses your existing local SQLite master data methods
      final customers = await repo.getCustomers();
      final products = await repo.getProducts();
      if (mounted) {
        setState(() {
          _customers = customers.map((c) => {'id': c.id, 'name': c.name}).toList();
          _products = products
              .map((p) => {'id': p.id, 'name': p.name, 'price': p.price, 'barcode': p.barcode})
              .toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        AppToast.showError("Load master data first via Delta Sync.");
      }
    }
  }

  void _addProductLine(Map<String, dynamic> product) {
    final existingIdx = _cartLines.indexWhere((l) => l['product_id'] == product['id']);
    setState(() {
      if (existingIdx >= 0) {
        _cartLines[existingIdx]['quantity'] += 1.0;
      } else {
        _cartLines.add({
          'product_id': product['id'],
          'name': product['name'],
          'quantity': 1.0,
          'price_unit': (product['price'] as num?)?.toDouble() ?? 0.0,
        });
      }
    });
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.pushNamed<String>(context, Routes.barcodeScannerScreen);
    if (code == null || code.isEmpty) return;
    final match = _products.where((p) => p['barcode'] == code).toList();
    if (match.isNotEmpty) {
      _addProductLine(match.first);
      AppToast.show("Added: ${match.first['name']}");
    } else {
      AppToast.showError("No product found with barcode: $code");
    }
  }

  double get _grandTotal => _cartLines.fold(
    0.0,
    (sum, l) => sum + ((l['quantity'] as double) * (l['price_unit'] as double)),
  );

  Future<void> _submitInvoice() async {
    if (_selectedCustomerId == null) {
      AppToast.showError("Please select a customer.");
      return;
    }
    if (_cartLines.isEmpty) {
      AppToast.showError("Add at least one product line.");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payloadLines = _cartLines
          .map(
            (l) => {
              'product_id': l['product_id'],
              'quantity': l['quantity'],
              'price_unit': l['price_unit'],
            },
          )
          .toList();

      final res = await context.read<OdooRepository>().createCustomerInvoice(
        partnerId: _selectedCustomerId!,
        lines: payloadLines,
        autoPost: _autoPost,
      );

      AppToast.show(res['message'] ?? "Invoice Created");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      AppToast.showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Customer Invoice"),
        backgroundColor: Colors.amber.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Scan Product Barcode",
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: _isLoadingData
          ? const ShimmerCardSkeleton()
          : Column(
              children: [
                SoftShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedCustomerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Select Customer",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: _customers
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'] as int,
                                child: Text(c['name'] as String, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCustomerId = val),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Add Product to Invoice",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_box_outlined),
                        ),
                        items: _products
                            .map(
                              (p) => DropdownMenuItem<int>(
                                value: p['id'] as int,
                                child: Text(
                                  "${p['name']} (${_fmt.format(p['price'])})",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (prodId) {
                          if (prodId == null) return;
                          final prod = _products.firstWhere((p) => p['id'] == prodId);
                          _addProductLine(prod);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Confirm & Post Invoice Immediately"),
                        subtitle: const Text("Off = Save as Draft in Odoo"),
                        value: _autoPost,
                        activeColor: Colors.amber.shade800,
                        onChanged: (v) => setState(() => _autoPost = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _cartLines.isEmpty
                      ? const Center(child: Text("Select or scan products to add invoice lines."))
                      : ListView.builder(
                          itemCount: _cartLines.length,
                          itemBuilder: (_, i) {
                            final line = _cartLines[i];
                            final sub =
                                (line['quantity'] as double) * (line['price_unit'] as double);
                            return SoftShadowCard(
                              padding: EdgeInsets.zero,
                              child: ListTile(
                                title: Text(
                                  line['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "Qty: ${line['quantity']} × ${_fmt.format(line['price_unit'])} = ${_fmt.format(sub)}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          if (line['quantity'] > 1) {
                                            line['quantity'] -= 1.0;
                                          } else {
                                            _cartLines.removeAt(i);
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => setState(() => line['quantity'] += 1.0),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: _isSubmitting ? null : _submitInvoice,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(
                _isSubmitting
                    ? "Creating Invoice..."
                    : "${_autoPost ? 'Post Invoice' : 'Save Draft'} (${_fmt.format(_grandTotal)})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
