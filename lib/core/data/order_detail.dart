import 'package:odoo_mobile_app/core/data/order_line.dart';

class OrderDetail {
  final String name;
  final String state;
  final String date;
  final List<OrderLine> lines;
  final int totalRecords;

  OrderDetail({
    required this.name,
    required this.state,
    required this.date,
    required this.lines,
    required this.totalRecords,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final rawProducts = json['products'] as List? ?? [];

    return OrderDetail(
      name: json['order_name'] ?? '',
      state: json['order_state'] ?? '',
      date: json['order_date'] ?? '',
      lines: rawProducts
          .map((i) => OrderLine.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
      totalRecords: meta['total_records'] ?? 0,
    );
  }
}
