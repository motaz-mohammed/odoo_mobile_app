class CustomerInvoiceLine {
  final int rankId;
  final int productId;
  final String product;
  final double quantity;
  final double priceUnit;
  final double discount;
  final double subtotal;
  final String uom;
  final String? imageBase64;

  CustomerInvoiceLine({
    required this.rankId,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.priceUnit,
    required this.discount,
    required this.subtotal,
    required this.uom,
    this.imageBase64,
  });

  factory CustomerInvoiceLine.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceLine(
      rankId: json['rank_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      product: json['product'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom'] ?? 'Units',
      imageBase64: json['image'],
    );
  }
}

class CustomerInvoiceDetail {
  final int invoiceId;
  final String invoiceName;
  final String customerName;
  final String invoiceDate;
  final String dueDate;
  final String invoiceOrigin;
  final String paymentState;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final double amountResidual;
  final List<CustomerInvoiceLine> lines;

  CustomerInvoiceDetail({
    required this.invoiceId,
    required this.invoiceName,
    required this.customerName,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceOrigin,
    required this.paymentState,
    required this.amountUntaxed,
    required this.amountTax,
    required this.amountTotal,
    required this.amountResidual,
    required this.lines,
  });

  factory CustomerInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? [];
    return CustomerInvoiceDetail(
      invoiceId: json['invoice_id'] ?? 0,
      invoiceName: json['invoice_name'] ?? '',
      customerName: json['customer_name'] ?? '',
      invoiceDate: json['invoice_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      invoiceOrigin: json['invoice_origin'] ?? '',
      paymentState: json['payment_state'] ?? 'not_paid',
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0.0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0.0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      amountResidual: (json['amount_residual'] as num?)?.toDouble() ?? 0.0,
      lines: rawLines
          .map((e) => CustomerInvoiceLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
