import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/lookup_product.dart';
import 'package:odoo_mobile_app/core/data/lookup_vendor.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';

class PurchaseOrderNewScreen extends StatefulWidget {
  const PurchaseOrderNewScreen({super.key});

  @override
  State<PurchaseOrderNewScreen> createState() => _PurchaseOrderNewScreenState();
}

class _PurchaseOrderNewScreenState extends State<PurchaseOrderNewScreen> {
  List<VendorLookup> _vendors = [];
  List<ProductLookup> _products = [];
  VendorLookup? _selectedVendor;
  ProductLookup? _selectedProduct;
  final _qtyCtrl = TextEditingController(text: "1");
  final _costCtrl = TextEditingController();
  final List<Map<String, dynamic>> _lines = [];
  bool _confirmPo = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final repo = context.read<OdooRepository>();
    final v = await repo.getVendors();
    final p = await repo.getProducts();
    if (mounted) {
      setState(() {
        _vendors = v;
        _products = p;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("New Purchase Order")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<VendorLookup>(
            initialValue: _selectedVendor,
            decoration: const InputDecoration(labelText: "Select Vendor", border: OutlineInputBorder()),
            items: _vendors.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
            onChanged: (v) => setState(() => _selectedVendor = v),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProductLookup>(
            initialValue: _selectedProduct,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Select Product", border: OutlineInputBorder()),
            items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (p) {
              setState(() {
                _selectedProduct = p;
                _costCtrl.text = (p?.price ?? 0.0).toString();
              });
            },
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
                  controller: _costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Cost Price", border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (_selectedProduct == null) return;
                  setState(() {
                    _lines.add({
                      "product_id": _selectedProduct!.id,
                      "product_name": _selectedProduct!.name,
                      "quantity": double.tryParse(_qtyCtrl.text) ?? 1.0,
                      "price_unit": double.tryParse(_costCtrl.text) ?? 0.0,
                    });
                    _selectedProduct = null;
                  });
                },
                child: const Text("Add"),
              ),
            ],
          ),
          const Divider(height: 28),
          ..._lines.asMap().entries.map((e) => ListTile(
                title: Text(e.value['product_name']),
                subtitle: Text("Qty: ${e.value['quantity']} x ${e.value['price_unit']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _lines.removeAt(e.key)),
                ),
              )),
          SwitchListTile(
            title: const Text("Confirm Purchase Order immediately"),
            value: _confirmPo,
            onChanged: (v) => setState(() => _confirmPo = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () async {
                if (_selectedVendor == null || _lines.isEmpty) {
                  AppToast.showError("Select vendor and add at least one product.");
                  return;
                }
                final res = await context.read<OdooRepository>().createPurchaseOrder(
                      _selectedVendor!.id,
                      _lines,
                      vendorName: _selectedVendor!.name,
                      confirm: _confirmPo,
                    );
                AppToast.show(res.message);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("SUBMIT PURCHASE ORDER"),
            ),
          ),
        ],
      ),
    );
  }
}
