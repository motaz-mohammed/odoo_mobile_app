import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/warehouse_picking.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/services/report_export_service.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';

class WarehousePickingDetailsScreen extends StatefulWidget {
  final int pickingId;
  const WarehousePickingDetailsScreen({super.key, required this.pickingId});

  @override
  State<WarehousePickingDetailsScreen> createState() => _WarehousePickingDetailsScreenState();
}

class _WarehousePickingDetailsScreenState extends State<WarehousePickingDetailsScreen> {
  PickingDetail? _detail;
  bool _loading = true;
  bool _validating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<OdooRepository>().fetchPickingDetails(widget.pickingId);
      if (mounted) {
        setState(() {
          _detail = d;
          _loading = false;
        });
      }
    } catch (e) {
      AppToast.showError(e.toString());
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _scanItemBarcode() async {
    if (_detail == null) return;
    final scanned = await Navigator.pushNamed(context, Routes.barcodeScannerScreen) as String?;
    if (scanned == null) return;

    final match = _detail!.moves.where((m) => m.barcode.trim() == scanned.trim()).toList();
    if (match.isNotEmpty) {
      setState(() => match.first.doneQty += 1);
      AppToast.show("Verified +1 for ${match.first.productName}");
    } else {
      AppToast.showError("Barcode $scanned is not in this transfer!");
    }
  }

  Future<void> _validateTransfer() async {
    if (_detail == null) return;
    setState(() => _validating = true);
    try {
      final res = await context
          .read<OdooRepository>()
          .validateWarehousePicking(_detail!.pickingId, _detail!.moves);
      AppToast.show(res['message'] ?? "Transfer Validated!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      AppToast.showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final d = _detail!;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.name),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Scan Product Barcode",
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: d.state == 'done' ? null : _scanItemBarcode,
          ),
          IconButton(
            tooltip: "Print PDF Transfer Slip",
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => ReportExportService.printPickingPdf(d),
          ),
        ],
      ),
      body: Column(
        children: [
          SoftShadowCard(
            child: ListTile(
              title: Text(d.partnerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Origin: ${d.origin} • Status: ${d.state.toUpperCase()}"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: d.moves.length,
              itemBuilder: (_, i) {
                final m = d.moves[i];
                return SoftShadowCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(m.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Barcode: ${m.barcode.isEmpty ? 'N/A' : m.barcode}\nDemand: ${m.demandQty} ${m.uom}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: d.state == 'done'
                              ? null
                              : () => setState(() => m.doneQty = (m.doneQty - 1).clamp(0, 99999)),
                        ),
                        Text("${m.doneQty}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                          onPressed: d.state == 'done' ? null : () => setState(() => m.doneQty += 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (d.state != 'done')
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.check_circle),
                  label: Text(_validating ? "VALIDATING..." : "VALIDATE TRANSFER IN ODOO"),
                  onPressed: _validating ? null : _validateTransfer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
