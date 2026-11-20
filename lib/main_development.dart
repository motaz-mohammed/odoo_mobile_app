import 'package:flutter/material.dart';
import 'package:odoo_mobile_app/core/database/local_db_helper.dart';
import 'package:odoo_mobile_app/core/routing/app_router.dart';
import 'package:odoo_mobile_app/odoo_mobile_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize relational SQLite database before app launch
  await LocalDbHelper.instance.database;

  runApp(OdooMobileApp(appRouter: AppRouter()));
}
