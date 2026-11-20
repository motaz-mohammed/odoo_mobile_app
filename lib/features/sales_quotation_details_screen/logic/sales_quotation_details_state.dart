// sales_quotation_details_state.dart
import 'package:odoo_mobile_app/core/data/order_detail.dart';

abstract class SalesQuotationDetailsState {}
class SalesQuotationDetailsInitial extends SalesQuotationDetailsState {}
class SalesQuotationDetailsLoading extends SalesQuotationDetailsState {}
class SalesQuotationDetailsLoaded extends SalesQuotationDetailsState {
  final OrderDetail order;
  SalesQuotationDetailsLoaded({required this.order});
}
class SalesQuotationDetailsError extends SalesQuotationDetailsState {
  final String errorMessage;
  SalesQuotationDetailsError({required this.errorMessage});
}
