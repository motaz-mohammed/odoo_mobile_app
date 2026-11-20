// lib/features/sales_quotation_new_screen/logic/form_cubit/quotation_form_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'quotation_form_state.dart';

class QuotationFormCubit extends Cubit<QuotationFormState> {
  final OdooRepository repository;
  QuotationFormCubit(this.repository) : super(FormInitial());

  Future<void> initializeForm({int? zoneId}) async {
    emit(FormLoadingData());
    try {
      final zones = await repository.getAssignedZones();
      final customers = await repository.getCustomers(zoneId: zoneId);
      final products = await repository.getProducts();
      emit(FormDataLoaded(customers: customers, products: products, zones: zones));
    } catch (e) {
      emit(FormLoadError(e.toString()));
    }
  }
}
