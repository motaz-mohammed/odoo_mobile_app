class QuotationResponse {
  final String status;
  final String message;
  final int orderId;
  final String orderName;
  final double amountTotal;

  QuotationResponse({
    required this.status,
    required this.message,
    required this.orderId,
    required this.orderName,
    required this.amountTotal,
  });

  factory QuotationResponse.fromJson(Map<String, dynamic> json) {
    return QuotationResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      orderId: json['order_id'] ?? 0,
      orderName: json['order_name'] ?? '',
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
