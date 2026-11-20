class OrderLine {
  final int rankId;
  final String product;
  final double quantity;
  final double price;
  final double subtotal;
  final String? imageBase64;

  OrderLine({
    required this.rankId,
    required this.product,
    required this.quantity,
    required this.price,
    this.imageBase64,
    required this.subtotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      rankId: json['rank_id'] ?? 0,
      product: json['product'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price_unit'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      imageBase64: json['image'],
    );
  }
}
