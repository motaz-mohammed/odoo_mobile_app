// sales_quotation_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'sales_quotation_state.dart';

class SalesQuotationCubit extends Cubit<SalesQuotationState> {
  final OdooRepository repository;

  SalesQuotationCubit(this.repository) : super(SalesQuotationInitial()) {
    getQuotations();
  }

  Future<void> getQuotations() async {
    emit(SalesQuotationLoading());
    try {
      final data = await repository.fetchQuotation();
      emit(SalesQuotationLoaded(orders: data.recentOrders));
    } catch (e) {
      emit(SalesQuotationError(errorMessage: e.toString().replaceAll("Exception: ", "")));
    }
  }
}
