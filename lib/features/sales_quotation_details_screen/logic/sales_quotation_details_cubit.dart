// sales_quotation_details_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/order_detail.dart';
import 'package:odoo_mobile_app/core/data/order_line.dart';
import 'package:odoo_mobile_app/core/networking/odoo_service.dart';
import 'sales_quotation_details_state.dart';

class SalesQuotationDetailsCubit extends Cubit<SalesQuotationDetailsState> {
  final OdooService service;
  final int orderId;

  SalesQuotationDetailsCubit({required this.service, required this.orderId})
      : super(SalesQuotationDetailsInitial()) {
    loadOrderDetails();
  }

  Future<void> loadOrderDetails() async {
    emit(SalesQuotationDetailsLoading());
    try {
      int offset = 0;
      const int limit = 20;
      final List<OrderLine> allLines = [];
      OrderDetail? header;
      bool more = true;

      while (more) {
        final page = await service.getOrderDetails(orderId, limit, offset);
        allLines.addAll(page.lines);
        offset += limit;
        header = OrderDetail(
          name: page.name,
          state: page.state,
          date: page.date,
          lines: List.from(allLines),
          totalRecords: page.totalRecords,
        );
        if (allLines.length >= page.totalRecords || page.lines.isEmpty) {
          more = false;
        }
      }
      if (!isClosed && header != null) {
        emit(SalesQuotationDetailsLoaded(order: header));
      }
    } catch (e) {
      if (!isClosed) {
        emit(SalesQuotationDetailsError(errorMessage: e.toString().replaceAll("Exception: ", "")));
      }
    }
  }
}
