// lib/features/sales_quotation_new_screen/logic/cubit/quotation_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/quotation_response.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';

abstract class QuotationState {}

class QuotationInitial extends QuotationState {}

class QuotationSubmitting extends QuotationState {}

class QuotationSuccess extends QuotationState {
  final QuotationResponse response;
  QuotationSuccess(this.response);
}

class QuotationError extends QuotationState {
  final String errorMessage;
  QuotationError(this.errorMessage);
}

class QuotationCubit extends Cubit<QuotationState> {
  final OdooRepository repository;
  QuotationCubit(this.repository) : super(QuotationInitial());

  Future<void> submitQuotation({
    required int partnerId,
    required String partnerName,
    required List<Map<String, dynamic>> orderLines,
    bool confirm = false,
  }) async {
    emit(QuotationSubmitting());
    try {
      final res = await repository.createQuotation(
        partnerId,
        orderLines,
        partnerName: partnerName,
        confirm: confirm,
      );
      emit(QuotationSuccess(res));
    } catch (e) {
      emit(QuotationError(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
