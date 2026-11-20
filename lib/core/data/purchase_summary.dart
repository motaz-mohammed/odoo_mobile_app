class PurchaseSummary {
  final int id;
  final String name;
  final String vendorName;
  final String dateOrder;
  final double amountTotal;
  final String state;

  PurchaseSummary({
    required this.id,
    required this.name,
    required this.vendorName,
    required this.dateOrder,
    required this.amountTotal,
    required this.state,
  });

  factory PurchaseSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
      dateOrder: json['date_order'] ?? '',
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] ?? 'draft',
    );
  }
}
