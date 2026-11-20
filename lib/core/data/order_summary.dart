class OrderSummary {
  final int id;
  final String name;
  final String partnerName;
  final String dateOrder;
  final double total;
  final String state;

  OrderSummary({
    required this.id,
    required this.name,
    required this.partnerName,
    this.dateOrder = '',
    required this.total,
    this.state = 'draft',
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      partnerName: json['partner_name'] ?? json['partner_id'] ?? 'Unknown',
      dateOrder: json['date_order'] ?? '',
      total: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
      state: json['state'] ?? 'draft',
    );
  }
}
