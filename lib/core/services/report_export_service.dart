import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:odoo_mobile_app/core/data/customer_invoice_detail.dart';
import 'package:odoo_mobile_app/core/data/order_detail.dart';
import 'package:odoo_mobile_app/core/data/order_summary.dart';
import 'package:odoo_mobile_app/core/data/purchase_detail.dart';
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
  static pw.Document _buildOrderPdf(OrderDetail order) {
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
                pw.Text(
                  'Odoo Mobile Manager - Order Report',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  order.name,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo,
                  ),
                ),
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
            data: order.lines
                .map(
                  (l) => [
                    '${l.rankId}',
                    l.product,
                    _numFmt.format(l.quantity),
                    _numFmt.format(l.price),
                    _numFmt.format(l.subtotal),
                  ],
                )
                .toList(),
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
    return pdf;
  }

  static Future<void> printOrShareOrderPdf(OrderDetail order) async {
    final pdf = _buildOrderPdf(order);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${order.name}.pdf');
  }

  static Future<void> shareOrderPdfToApps(OrderDetail order) async {
    final pdf = _buildOrderPdf(order);
    await _saveAndSharePdf(pdf, '${order.name}.pdf', 'Sales Order ${order.name}');
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

  // ==================== 3. EXCEL & PDF: PURCHASE ORDERS ====================
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

  static pw.Document _buildPurchaseOrderPdf(PurchaseDetail po) {
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
                pw.Text(
                  'Purchase Order Report',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  po.poName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          pw.Text('Vendor: ${po.vendorName}'),
          pw.Text('Date: ${po.orderDate}'),
          pw.Text('Status: ${po.orderState.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
            headers: ['#', 'Product', 'Qty', 'Received', 'Unit Price', 'Subtotal'],
            data: po.lines
                .map(
                  (l) => [
                    '${l.rankId}',
                    l.product,
                    _numFmt.format(l.quantity),
                    _numFmt.format(l.qtyReceived),
                    _numFmt.format(l.priceUnit),
                    _numFmt.format(l.subtotal),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Grand Total: ${_numFmt.format(po.amountTotal)}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> printPurchaseOrderPdf(PurchaseDetail po) async {
    final pdf = _buildPurchaseOrderPdf(po);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${po.poName}.pdf');
  }

  static Future<void> sharePurchaseOrderPdfToApps(PurchaseDetail po) async {
    final pdf = _buildPurchaseOrderPdf(po);
    await _saveAndSharePdf(pdf, '${po.poName}.pdf', 'Purchase Order ${po.poName}');
  }

  // ==================== 4. PDF: WAREHOUSE PICKING ====================
  static pw.Document _buildPickingPdf(PickingDetail picking) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Warehouse Transfer Slip: ${picking.name}',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Partner: ${picking.partnerName}'),
          pw.Text('Source Document: ${picking.origin}'),
          pw.Text('Status: ${picking.state.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            headers: ['Product', 'Barcode', 'Demand', 'Done', 'UoM'],
            data: picking.moves
                .map(
                  (m) => [
                    m.productName,
                    m.barcode,
                    _numFmt.format(m.demandQty),
                    _numFmt.format(m.doneQty),
                    m.uom,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> printPickingPdf(PickingDetail picking) async {
    final pdf = _buildPickingPdf(picking);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${picking.name}.pdf');
  }

  static Future<void> sharePickingPdfToApps(PickingDetail picking) async {
    final pdf = _buildPickingPdf(picking);
    await _saveAndSharePdf(pdf, '${picking.name}.pdf', 'Warehouse Slip ${picking.name}');
  }

  // ==================== 5. PDF: CUSTOMER INVOICE ====================
  static pw.Document _buildCustomerInvoicePdf(CustomerInvoiceDetail inv) {
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
                pw.Text(
                  'Customer Invoice',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  inv.invoiceName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800,
                  ),
                ),
              ],
            ),
          ),
          pw.Text('Customer: ${inv.customerName}'),
          pw.Text('Invoice Date: ${inv.invoiceDate}   |   Due Date: ${inv.dueDate}'),
          if (inv.invoiceOrigin.isNotEmpty) pw.Text('Source Document: ${inv.invoiceOrigin}'),
          pw.Text('Payment Status: ${inv.paymentState.toUpperCase()}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.amber800),
            headers: ['#', 'Product', 'Qty', 'Unit Price', 'Subtotal'],
            data: inv.lines
                .map(
                  (l) => [
                    '${l.rankId}',
                    l.product,
                    '${_numFmt.format(l.quantity)} ${l.uom}',
                    _numFmt.format(l.priceUnit),
                    _numFmt.format(l.subtotal),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Untaxed: ${_numFmt.format(inv.amountUntaxed)}'),
                pw.Text('Tax: ${_numFmt.format(inv.amountTax)}'),
                pw.Text(
                  'Grand Total: ${_numFmt.format(inv.amountTotal)}',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Amount Due: ${_numFmt.format(inv.amountResidual)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> printCustomerInvoicePdf(CustomerInvoiceDetail inv) async {
    final pdf = _buildCustomerInvoicePdf(inv);
    await Printing.layoutPdf(onLayout: (_) async => pdf.save(), name: '${inv.invoiceName}.pdf');
  }

  static Future<void> shareCustomerInvoicePdfToApps(CustomerInvoiceDetail inv) async {
    final pdf = _buildCustomerInvoicePdf(inv);
    await _saveAndSharePdf(pdf, '${inv.invoiceName}.pdf', 'Customer Invoice ${inv.invoiceName}');
  }

  // ==================== SHARED FILE HELPERS ====================
  static Future<void> _saveAndSharePdf(
    pw.Document pdf,
    String rawFileName,
    String shareText,
  ) async {
    final bytes = await pdf.save();
    final safeName = rawFileName.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')], text: shareText);
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
