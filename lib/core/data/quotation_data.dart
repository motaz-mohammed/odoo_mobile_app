import 'package:odoo_mobile_app/core/data/order_summary.dart';

class QuotationData {
  final int totalSalesCount;
  final List<OrderSummary> recentOrders;

  QuotationData({required this.totalSalesCount, required this.recentOrders});

  factory QuotationData.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['recent_orders'] as List? ?? [];
    return QuotationData(
      totalSalesCount: json['total_sales_count'] ?? 0,
      recentOrders: rawOrders
          .map((i) => OrderSummary.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }
}
