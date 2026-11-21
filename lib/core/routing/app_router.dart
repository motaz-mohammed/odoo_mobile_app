import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/networking/odoo_service.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/features/about/ui/about_developer_screen.dart';
import 'package:odoo_mobile_app/features/accounting/ui/customer_invoice_details_screen.dart';
import 'package:odoo_mobile_app/features/accounting/ui/customer_invoice_new_screen.dart';
import 'package:odoo_mobile_app/features/accounting/ui/customer_invoices_screen.dart';
import 'package:odoo_mobile_app/features/home/ui/home_screen.dart';
import 'package:odoo_mobile_app/features/login/logic/cubits/login_cubit.dart';
import 'package:odoo_mobile_app/features/login/ui/login_screen.dart';
import 'package:odoo_mobile_app/features/offline_sync_center_screen/ui/offline_sync_center_screen.dart';
import 'package:odoo_mobile_app/features/purchase/ui/purchase_order_details_screen.dart';
import 'package:odoo_mobile_app/features/purchase/ui/purchase_order_new_screen.dart';
import 'package:odoo_mobile_app/features/purchase/ui/purchase_orders_screen.dart';
import 'package:odoo_mobile_app/features/sales_quotation_details_screen/logic/sales_quotation_details_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_details_screen/logic/sales_quotation_details_screen.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/logic/cubit/quotation_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/logic/form_cubit/quotation_form_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotation_new_screen/ui/sales_quotation_new.dart';
import 'package:odoo_mobile_app/features/sales_quotations_view_screen/logic/cubits/sales_quotation_cubit.dart';
import 'package:odoo_mobile_app/features/sales_quotations_view_screen/ui/sales_quotations_view_screen.dart';
import 'package:odoo_mobile_app/features/screens_barcode_reader/ui/screens_barcode_reader.dart';
import 'package:odoo_mobile_app/features/splash/splash_screen.dart';
import 'package:odoo_mobile_app/features/warehouse/ui/warehouse_picking_details_screen.dart';
import 'package:odoo_mobile_app/features/warehouse/ui/warehouse_pickings_screen.dart';

class AppRouter {
  late final OdooService _odooService;
  late final OdooRepository _odooRepository;

  OdooRepository get odooRepository => _odooRepository;

  AppRouter() {
    _odooService = OdooService();
    _odooRepository = OdooRepository(_odooService);
  }

  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreen:
        return MaterialPageRoute(
          builder: (_) =>
              RepositoryProvider.value(value: _odooRepository, child: const SplashScreen()),
        );

      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: BlocProvider(
              create: (_) => LoginCubit(_odooRepository),
              child: const LoginScreen(),
            ),
          ),
        );

      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (_) =>
              RepositoryProvider.value(value: _odooRepository, child: const HomeScreen()),
        );

      case Routes.salesViewQuotations:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: BlocProvider(
              create: (_) => SalesQuotationCubit(_odooRepository),
              child: const SalesQuotationsView(),
            ),
          ),
        );

      case Routes.salesQuotationDetails:
        final orderId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => SalesQuotationDetailsCubit(service: _odooService, orderId: orderId),
            child: const SalesQuotationDetails(),
          ),
        );

      case Routes.salesNewQuotations:
        return MaterialPageRoute(
          builder: (context) => RepositoryProvider.value(
            value: _odooRepository,
            child: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => QuotationFormCubit(_odooRepository)..initializeForm()),
                BlocProvider(create: (_) => QuotationCubit(_odooRepository)),
              ],
              child: const SalesQuotationNew(),
            ),
          ),
        );

      case Routes.purchaseOrdersScreen:
        return MaterialPageRoute(
          builder: (_) =>
              RepositoryProvider.value(value: _odooRepository, child: const PurchaseOrdersScreen()),
        );

      case Routes.purchaseOrderNewScreen:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: const PurchaseOrderNewScreen(),
          ),
        );

      case Routes.purchaseOrderDetailsScreen:
        final poId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: PurchaseOrderDetailsScreen(poId: poId),
          ),
        );

      case Routes.warehousePickingsScreen:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: const WarehousePickingsScreen(),
          ),
        );

      case Routes.warehousePickingDetailsScreen:
        final pickingId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: WarehousePickingDetailsScreen(pickingId: pickingId),
          ),
        );

      case Routes.offlineSyncCenter:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: const OfflineSyncCenterScreen(),
          ),
        );

      case Routes.aboutDeveloperScreen:
        return MaterialPageRoute(builder: (_) => const AboutDeveloperScreen());

      case Routes.barcodeScannerScreen:
        return MaterialPageRoute<String>(builder: (_) => const BarcodeScannerScreen());

      case Routes.customerInvoicesScreen:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: const CustomerInvoicesScreen(),
          ),
        );

      case Routes.customerInvoiceDetailsScreen:
        final invoiceId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: CustomerInvoiceDetailsScreen(invoiceId: invoiceId),
          ),
        );

      case Routes.customerInvoiceNewScreen:
        return MaterialPageRoute(
          builder: (_) => RepositoryProvider.value(
            value: _odooRepository,
            child: const CustomerInvoiceNewScreen(),
          ),
        );

      default:
        return null;
    }
  }
}
