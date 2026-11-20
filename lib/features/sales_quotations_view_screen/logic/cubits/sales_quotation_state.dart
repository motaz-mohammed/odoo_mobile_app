// sales_quotation_state.dart
import 'package:odoo_mobile_app/core/data/order_summary.dart';

abstract class SalesQuotationState {}
class SalesQuotationInitial extends SalesQuotationState {}
class SalesQuotationLoading extends SalesQuotationState {}
class SalesQuotationLoaded extends SalesQuotationState {
  final List<OrderSummary> orders;
  SalesQuotationLoaded({required this.orders});
}
class SalesQuotationError extends SalesQuotationState {
  final String errorMessage;
  SalesQuotationError({required this.errorMessage});
}
