import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/data/user_session.dart';
import 'package:odoo_mobile_app/core/helpers/toast_helper.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'package:odoo_mobile_app/core/routing/routes.dart';
import 'package:odoo_mobile_app/core/widgets/shimmer_skeleton.dart';
import 'package:odoo_mobile_app/features/offline_sync_center_screen/logic/cubits/sync_center_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserSession? _session;
  bool _isSyncingDelta = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await context.read<OdooRepository>().getCurrentUserSession();
    if (mounted) setState(() => _session = session);
  }

  Future<void> _runDeltaSync() async {
    setState(() => _isSyncingDelta = true);
    try {
      final counts = await context.read<OdooRepository>().syncMasterDataToSqlite();
      AppToast.show(
        "Delta Sync Done: ${counts['customers']} Customers, ${counts['vendors']} Vendors, ${counts['products']} Products",
      );
    } catch (e) {
      AppToast.showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isSyncingDelta = false);
    }
  }

  Future<void> _handleLogout() async {
    await context.read<OdooRepository>().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, Routes.loginScreen, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = _session?.zones ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_session?.name ?? "Odoo Mobile Hub", style: const TextStyle(fontSize: 18)),
            Text(
              _session?.companyName ?? "Field ERP",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Delta Sync SQLite",
            icon: _isSyncingDelta
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync),
            onPressed: _isSyncingDelta ? null : _runDeltaSync,
          ),
          IconButton(tooltip: "Logout", icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Geographic Zones Banner
          SoftShadowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.indigo, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "Assigned Geographic Zones",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                zones.isEmpty
                    ? const Text(
                        "All Territories (Unrestricted)",
                        style: TextStyle(color: Colors.grey),
                      )
                    : Wrap(
                        spacing: 8,
                        children: zones
                            .map(
                              (z) => Chip(
                                label: Text("${z.code} • ${z.name}"),
                                backgroundColor: Colors.indigo.shade50,
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),

          // Offline Queue Banner
          BlocBuilder<SyncCenterCubit, SyncCenterState>(
            builder: (context, syncState) {
              final drafts = syncState is SyncCenterLoaded
                  ? syncState.drafts
                  : (syncState is SyncCenterActionSuccess ? syncState.drafts : []);
              if (drafts.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cloud_off),
                  label: Text("Pending Offline Queue (${drafts.length}) — Tap to Sync"),
                  onPressed: () async {
                    final cubit = context.read<SyncCenterCubit>();
                    await Navigator.pushNamed(context, Routes.offlineSyncCenter);
                    if (mounted) cubit.loadDrafts();
                  },
                ),
              );
            },
          ),

          // SALES MODULE
          if (_session?.isSales ?? true) ...[
            _sectionTitle("Sales & Distribution"),
            _menuCard(
              title: "Sales Quotations & Orders",
              subtitle: "View orders, inspect details & export PDF / Excel",
              icon: Icons.receipt_long,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(context, Routes.salesViewQuotations),
            ),
            _menuCard(
              title: "Create New Quotation",
              subtitle: "Zone-filtered customers, barcode scan & offline SQLite draft",
              icon: Icons.add_shopping_cart,
              color: Colors.green.shade700,
              onTap: () async {
                final cubit = context.read<SyncCenterCubit>();
                await Navigator.pushNamed(context, Routes.salesNewQuotations);
                if (mounted) cubit.loadDrafts();
              },
            ),
          ],

          // ACCOUNTING / INVOICING MODULE
          _sectionTitle("Accounting & Collections"),
          _menuCard(
            title: "Customer Invoices & Payments",
            subtitle: "Track open balances, paid invoices & register field payments",
            icon: Icons.account_balance_wallet,
            color: Colors.amber.shade800,
            onTap: () => Navigator.pushNamed(context, Routes.customerInvoicesScreen),
          ),

          // PURCHASE MODULE
          if (_session?.isPurchase ?? true) ...[
            _sectionTitle("Purchasing"),
            _menuCard(
              title: "Purchase Orders & RFQs",
              subtitle: "Browse supplier orders, confirm RFQs & export PDF",
              icon: Icons.shopping_bag,
              color: Colors.deepPurple,
              onTap: () => Navigator.pushNamed(context, Routes.purchaseOrdersScreen),
            ),
            _menuCard(
              title: "New Purchase Order",
              subtitle: "Create vendor order online or queue offline",
              icon: Icons.add_business,
              color: Colors.purple,
              onTap: () async {
                final cubit = context.read<SyncCenterCubit>();
                await Navigator.pushNamed(context, Routes.purchaseOrderNewScreen);
                if (mounted) cubit.loadDrafts();
              },
            ),
          ],

          // WAREHOUSE MODULE
          if (_session?.isWarehouse ?? true) ...[
            _sectionTitle("Warehouse Operations"),
            _menuCard(
              title: "Receipts & Zone Deliveries",
              subtitle: "Receive supplier goods & validate zone deliveries with barcode",
              icon: Icons.local_shipping,
              color: Colors.teal.shade700,
              onTap: () => Navigator.pushNamed(context, Routes.warehousePickingsScreen),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final userName = _session?.name ?? "Odoo Mobile Hub";
    final initials = userName.isNotEmpty ? userName[0].toUpperCase() : "O";

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E293B)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            accountName: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              _session?.companyName ?? "Field ERP",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF1E293B)),
                  title: const Text("Dashboard"),
                  onTap: () => Navigator.pop(context),
                ),

                // Sales Section
                if (_session?.isSales ?? true) ...[
                  const Divider(height: 1),
                  _drawerSectionLabel("SALES"),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                    title: const Text("Sales Orders & Quotations"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.salesViewQuotations);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.add_shopping_cart, color: Colors.green.shade700),
                    title: const Text("New Quotation"),
                    onTap: () async {
                      final cubit = context.read();
                      Navigator.pop(context);
                      await Navigator.pushNamed(context, Routes.salesNewQuotations);
                      if (mounted) cubit.loadDrafts();
                    },
                  ),
                ],
                // Accounting Section
                const Divider(height: 1),
                _drawerSectionLabel("ACCOUNTING"),
                ListTile(
                  leading: Icon(Icons.account_balance_wallet, color: Colors.amber.shade800),
                  title: const Text("Customer Invoices"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.customerInvoicesScreen);
                  },
                ),
                // Purchase Section
                if (_session?.isPurchase ?? true) ...[
                  const Divider(height: 1),
                  _drawerSectionLabel("PURCHASING"),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag, color: Colors.deepPurple),
                    title: const Text("Purchase Orders & RFQs"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.purchaseOrdersScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_business, color: Colors.purple),
                    title: const Text("New Purchase Order"),
                    onTap: () async {
                      final cubit = context.read();
                      Navigator.pop(context);
                      await Navigator.pushNamed(context, Routes.purchaseOrderNewScreen);
                      if (mounted) cubit.loadDrafts();
                    },
                  ),
                ],
                // Warehouse Section
                if (_session?.isWarehouse ?? true) ...[
                  const Divider(height: 1),
                  _drawerSectionLabel("WAREHOUSE"),
                  ListTile(
                    leading: Icon(Icons.local_shipping, color: Colors.teal.shade700),
                    title: const Text("Receipts & Deliveries"),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.warehousePickingsScreen);
                    },
                  ),
                ],
                // Sync & App Info
                const Divider(height: 1),
                _drawerSectionLabel("SYSTEM & SUPPORT"),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: Colors.indigo),
                  title: const Text("Sync Master Data"),
                  onTap: () {
                    Navigator.pop(context);
                    if (!_isSyncingDelta) _runDeltaSync();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sync_problem_outlined, color: Colors.orange),
                  title: const Text("Offline Sync Center"),
                  onTap: () async {
                    final cubit = context.read();
                    Navigator.pop(context);
                    await Navigator.pushNamed(context, Routes.offlineSyncCenter);
                    if (mounted) cubit.loadDrafts();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.deepPurple),
                  title: const Text(
                    "About & Developer Contact",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text("Motaz Osman • Qatar & KSA"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.aboutDeveloperScreen);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12, top: 2),
            child: Text(
              "Odoo 17 Mobile ERP • v1.0.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }

  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SoftShadowCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        onTap: onTap,
      ),
    );
  }
}
