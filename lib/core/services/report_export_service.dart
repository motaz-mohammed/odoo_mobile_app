import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/data/order_detail.dart';
import 'package:odoo_mobile_app/core/data/order_summary.dart';
import 'package:odoo_mobile_app/core/data/purchase_summary.dart';
import 'package:odoo_mobile_app/core/data/warehouse_picking.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportExportService {
  static final _numFmt = NumberFormat('#,##0.00', 'en_US');

  // ==================== 1. PDF: SINGLE ORDER / QUOTATION ====================
  static Future<void> printOrShareOrderPdf(OrderDetail order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Odoo Mobile Manager - Order Report',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text(order.name,
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Order Date: ${order.date}'),
          pw.Text('Status: ${order.state.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            headers: ['#', 'Product', 'Qty', 'Unit Price', 'Subtotal'],
            data: order.lines.map((l) => [
              '${l.rankId}',
              l.product,
              _numFmt.format(l.quantity),
              _numFmt.format(l.price),
              _numFmt.format(l.subtotal),
            ]).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Grand Total: ${_numFmt.format(order.lines.fold(0.0, (s, e) => s + e.subtotal))}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${order.name}.pdf');
  }

  // ==================== 2. EXCEL: SALES QUOTATIONS SUMMARY ====================
  static Future<void> exportSalesExcel(List<OrderSummary> orders) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Orders'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('Order Ref'),
      TextCellValue('Customer'),
      TextCellValue('Date'),
      TextCellValue('Status'),
      TextCellValue('Total Amount'),
    ]);

    for (final o in orders) {
      sheet.appendRow([
        TextCellValue(o.name),
        TextCellValue(o.partnerName),
        TextCellValue(o.dateOrder),
        TextCellValue(o.state.toUpperCase()),
        DoubleCellValue(o.total),
      ]);
    }

    await _saveAndShareExcel(excel, 'sales_orders_report.xlsx');
  }

  // ==================== 3. EXCEL: PURCHASE ORDERS SUMMARY ====================
  static Future<void> exportPurchasesExcel(List<PurchaseSummary> orders) async {
    final excel = Excel.createExcel();
    final sheet = excel['Purchase Orders'];
    excel.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('PO Ref'),
      TextCellValue('Vendor'),
      TextCellValue('Date'),
      TextCellValue('Status'),
      TextCellValue('Total Amount'),
    ]);

    for (final o in orders) {
      sheet.appendRow([
        TextCellValue(o.name),
        TextCellValue(o.vendorName),
        TextCellValue(o.dateOrder),
        TextCellValue(o.state.toUpperCase()),
        DoubleCellValue(o.amountTotal),
      ]);
    }

    await _saveAndShareExcel(excel, 'purchase_orders_report.xlsx');
  }

  // ==================== 4. PDF & EXCEL: WAREHOUSE PICKING ====================
  static Future<void> printPickingPdf(PickingDetail picking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Warehouse Transfer Slip: ${picking.name}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Partner: ${picking.partnerName}'),
          pw.Text('Source Document: ${picking.origin}'),
          pw.Text('Status: ${picking.state.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            headers: ['Product', 'Barcode', 'Demand', 'Done', 'UoM'],
            data: picking.moves.map((m) => [
              m.productName,
              m.barcode,
              _numFmt.format(m.demandQty),
              _numFmt.format(m.doneQty),
              m.uom,
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${picking.name}.pdf');
  }

  static Future<void> _saveAndShareExcel(Excel excel, String fileName) async {
    final bytes = excel.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: 'Exported Odoo Report: $fileName');
  }
}
