class PurchaseOrderLine {
  final int rankId;
  final int productId;
  final String product;
  final double quantity;
  final double qtyReceived;
  final double priceUnit;
  final double subtotal;
  final String uom;
  final String? imageBase64;

  PurchaseOrderLine({
    required this.rankId,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.qtyReceived,
    required this.priceUnit,
    required this.subtotal,
    required this.uom,
    this.imageBase64,
  });

  factory PurchaseOrderLine.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderLine(
      rankId: json['rank_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      product: json['product'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      qtyReceived: (json['qty_received'] as num?)?.toDouble() ?? 0.0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom'] ?? 'Units',
      imageBase64: json['image'],
    );
  }
}

class PurchaseDetail {
  final int poId;
  final String poName;
  final String vendorName;
  final String orderDate;
  final String orderState;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final List<PurchaseOrderLine> lines;

  PurchaseDetail({
    required this.poId,
    required this.poName,
    required this.vendorName,
    required this.orderDate,
    required this.orderState,
    required this.amountUntaxed,
    required this.amountTax,
    required this.amountTotal,
    required this.lines,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? [];
    return PurchaseDetail(
      poId: json['po_id'] ?? 0,
      poName: json['po_name'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      orderDate: json['order_date'] ?? '',
      orderState: json['order_state'] ?? '',
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0.0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0.0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      lines: rawLines
          .map((e) => PurchaseOrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
