import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/routing/app_router.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/theming/colors.dart';
import 'package:odoo_mobile_app/features/offline_sync_center_screen/logic/cubits/sync_center_cubit.dart';

class OdooMobileApp extends StatelessWidget {
  const OdooMobileApp({super.key, required this.appRouter});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    final odooRepository = appRouter.odooRepository;

    return MultiBlocProvider(
      providers: [
        BlocProvider<SyncCenterCubit>(
          create: (_) => SyncCenterCubit(odooRepository)..loadDrafts(),
        ),
      ],
      child: MaterialApp(
        title: 'Odoo 17 Mobile Manager',
        theme: ThemeData(
          primaryColor: AppColorsList.mainBlue,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColorsList.mainBlue),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.splashScreen,
        onGenerateRoute: appRouter.generateRoute,
      ),
    );
  }
}
