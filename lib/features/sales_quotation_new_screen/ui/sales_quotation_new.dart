// lib/features/sales_quotation_new_screen/ui/sales_quotation_new.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/lookup_customer.dart';
import 'package:odoo_mobile_app/core/data/lookup_product.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/logic/cubit/quotation_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/logic/form_cubit/quotation_form_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/logic/form_cubit/quotation_form_state.dart';

class SalesQuotationNew extends StatefulWidget {
  const SalesQuotationNew({super.key});

  @override
  State<SalesQuotationNew> createState() => _SalesQuotationNewState();
}

class _SalesQuotationNewState extends State<SalesQuotationNew> {
  CustomerLookup? _selectedCustomer;
  ProductLookup? _selectedProduct;
  int? _selectedZoneFilter;
  bool _confirmOrder = false;

  final _qtyCtrl = TextEditingController(text: "1");
  final _priceCtrl = TextEditingController();
  final List<Map<String, dynamic>> _lines = [];

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(
      0.0, (sum, l) => sum + ((l['quantity'] as double) * (l['price_unit'] as double)));

  void _addLine() {
    if (_selectedProduct == null) return;
    final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
    final price = double.tryParse(_priceCtrl.text) ?? _selectedProduct!.price;
    setState(() {
      _lines.add({
        "product_id": _selectedProduct!.id,
        "product_name": _selectedProduct!.name,
        "quantity": qty,
        "price_unit": price,
      });
      _selectedProduct = null;
      _qtyCtrl.text = "1";
      _priceCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Sales Quotation")),
      body: BlocListener<QuotationCubit, QuotationState>(
        listener: (context, state) {
          if (state is QuotationSuccess) {
            AppToast.show(state.response.message);
            Navigator.pop(context);
          } else if (state is QuotationError) {
            AppToast.showError(state.errorMessage);
          }
        },
        child: BlocBuilder<QuotationFormCubit, QuotationFormState>(
          builder: (context, state) {
            if (state is FormLoadingData) return const Center(child: CircularProgressIndicator());
            if (state is FormLoadError) return Center(child: Text(state.message));
            if (state is FormDataLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.zones.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedZoneFilter,
                      decoration: const InputDecoration(
                        labelText: "Filter Customers by Geographic Zone",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All My Assigned Zones")),
                        ...state.zones.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedZoneFilter = val;
                          _selectedCustomer = null;
                        });
                        context.read<QuotationFormCubit>().initializeForm(zoneId: val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<CustomerLookup>(
                    initialValue: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: "Select Zone Customer",
                      border: OutlineInputBorder(),
                    ),
                    items: state.customers
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedCustomer = c),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ProductLookup>(
                          initialValue: _selectedProduct,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: "Select Product",
                            border: OutlineInputBorder(),
                          ),
                          items: state.products
                              .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                              .toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedProduct = p;
                              _priceCtrl.text = (p?.price ?? 0.0).toString();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () async {
                          final code = await Navigator.pushNamed(context, Routes.barcodeScannerScreen)
                              as String?;
                          if (code != null && context.mounted) {
                            final found = await context.read<OdooRepository>().findProductByBarcode(code);
                            if (found != null) {
                              setState(() {
                                _selectedProduct = found;
                                _priceCtrl.text = found.price.toString();
                              });
                            } else {
                              AppToast.showError("No product with barcode: $code");
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Qty", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(onPressed: _addLine, child: const Text("Add")),
                    ],
                  ),
                  const Divider(height: 28),
                  ..._lines.asMap().entries.map((e) {
                    final l = e.value;
                    return ListTile(
                      title: Text(l['product_name']),
                      subtitle: Text("Qty: ${l['quantity']} x ${l['price_unit']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _lines.removeAt(e.key)),
                      ),
                    );
                  }),
                  SwitchListTile(
                    title: const Text("Confirm Sales Order immediately"),
                    value: _confirmOrder,
                    onChanged: (v) => setState(() => _confirmOrder = v),
                  ),
                  const SizedBox(height: 12),
                  Text("Total: ${_total.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () {
                        if (_selectedCustomer == null || _lines.isEmpty) {
                          AppToast.showError("Select a customer and add at least one product.");
                          return;
                        }
                        context.read<QuotationCubit>().submitQuotation(
                              partnerId: _selectedCustomer!.id,
                              partnerName: _selectedCustomer!.name,
                              orderLines: _lines,
                              confirm: _confirmOrder,
                            );
                      },
                      child: const Text("SUBMIT QUOTATION"),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
