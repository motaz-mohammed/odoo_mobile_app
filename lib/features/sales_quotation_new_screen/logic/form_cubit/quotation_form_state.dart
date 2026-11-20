// lib/features/sales_quotation_new_screen/logic/form_cubit/quotation_form_state.dart
import 'package:odoo_mobile_app/core/data/lookup_customer.dart';
import 'package:odoo_mobile_app/core/data/lookup_product.dart';
import 'package:odoo_mobile_app/core/data/user_session.dart';

abstract class QuotationFormState {}
class FormInitial extends QuotationFormState {}
class FormLoadingData extends QuotationFormState {}
class FormDataLoaded extends QuotationFormState {
  final List<CustomerLookup> customers;
  final List<ProductLookup> products;
  final List<GeographicZone> zones;
  FormDataLoaded({required this.customers, required this.products, required this.zones});
}
class FormLoadError extends QuotationFormState {
  final String message;
  FormLoadError(this.message);
}
