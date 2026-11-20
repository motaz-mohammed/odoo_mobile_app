import 'dart:async';
import 'dart:io';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:odoo_mobile_app/core/data/lookup_customer.dart';
import 'package:odoo_mobile_app/core/data/lookup_product.dart';
import 'package:odoo_mobile_app/core/data/lookup_vendor.dart';
import 'package:odoo_mobile_app/core/data/order_detail.dart';
import 'package:odoo_mobile_app/core/data/purchase_summary.dart';
import 'package:odoo_mobile_app/core/data/quotation_data.dart';
import 'package:odoo_mobile_app/core/data/quotation_response.dart';
import 'package:odoo_mobile_app/core/data/user_session.dart';
import 'package:odoo_mobile_app/core/data/warehouse_picking.dart';
import 'package:odoo_mobile_app/core/database/local_db_helper.dart';
import 'package:odoo_mobile_app/core/networking/odoo_service.dart';

class OdooRepository {
  final OdooService _odooService;
  final LocalDbHelper _localDb = LocalDbHelper.instance;
  final InternetConnectionChecker _connectionChecker;

  OdooRepository(this._odooService, {InternetConnectionChecker? connectionChecker})
    : _connectionChecker = connectionChecker ?? InternetConnectionChecker();

  Stream<InternetConnectionStatus> get connectionStatusStream => _connectionChecker.onStatusChange;
  OdooService get odooService => _odooService;

  Future<bool> isOnlineMode() async => await _connectionChecker.hasConnection;

  // ==================== AUTH & ZONES ====================

  Future<UserSession> login(String user, String pass, {String? db}) async {
    final session = await _odooService.login(user, pass, db: db);
    await _localDb.saveUserZones(session.zones.map((z) => z.toMap()).toList());
    // Trigger initial SQLite master-data population right after login
    await syncMasterDataToSqlite(forceFull: true);
    return session;
  }

  Future<UserSession?> getCurrentUserSession() async {
    return await _odooService.getSavedUserSession();
  }

  Future<List<GeographicZone>> getAssignedZones() async {
    final rows = await _localDb.getUserZones();
    return rows.map((r) => GeographicZone.fromJson(r)).toList();
  }

  Future<bool> hasSavedSession() async => await _odooService.hasSavedSession();

  Future<void> logout() async {
    await _odooService.clearSession();
    await _localDb.clearAllOnLogout();
  }

  // ==================== DELTA SYNC -> SQLITE ====================

  Future<Map<String, int>> syncMasterDataToSqlite({bool forceFull = false}) async {
    if (!await isOnlineMode()) {
      throw Exception("Offline: Cannot sync master data from Odoo.");
    }

    final lastSync = forceFull ? null : await _odooService.getLastSyncTimestamp();
    final response = await _odooService.fetchMasterDataDelta(lastSync: lastSync);

    final data = response['data'] as Map<String, dynamic>? ?? {};
    final customers = (data['customers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final vendors = (data['vendors'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final products = (data['products'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final taxes = (data['taxes'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    await _localDb.upsertMasterData(
      customers: customers,
      vendors: vendors,
      products: products,
      taxes: taxes,
    );

    if (response['server_timestamp'] != null) {
      await _odooService.saveLastSyncTimestamp(response['server_timestamp'].toString());
    }

    return {'customers': customers.length, 'vendors': vendors.length, 'products': products.length};
  }

  // ==================== LOCAL SQLITE LOOKUPS ====================

  Future<List<CustomerLookup>> getCustomers({int? zoneId, bool refreshFromServer = false}) async {
    if (refreshFromServer && await isOnlineMode()) {
      try {
        await syncMasterDataToSqlite();
      } catch (_) {}
    }
    final rows = await _localDb.getCustomers(zoneId: zoneId);
    return rows.map((r) => CustomerLookup.fromJson(r)).toList();
  }

  Future<List<VendorLookup>> getVendors({bool refreshFromServer = false}) async {
    if (refreshFromServer && await isOnlineMode()) {
      try {
        await syncMasterDataToSqlite();
      } catch (_) {}
    }
    final rows = await _localDb.getVendors();
    return rows.map((r) => VendorLookup.fromJson(r)).toList();
  }

  Future<List<ProductLookup>> getProducts({bool refreshFromServer = false}) async {
    if (refreshFromServer && await isOnlineMode()) {
      try {
        await syncMasterDataToSqlite();
      } catch (_) {}
    }
    final rows = await _localDb.getProducts();
    return rows.map((r) => ProductLookup.fromJson(r)).toList();
  }

  Future<ProductLookup?> findProductByBarcode(String barcode) async {
    final row = await _localDb.findProductByBarcode(barcode);
    return row != null ? ProductLookup.fromJson(row) : null;
  }

  // ==================== SALES ORDERS ====================

  Future<QuotationData> fetchQuotation() async {
    return await _odooService.getQuotationData();
  }

  Future<OrderDetail> fetchOrderDetail(int orderId, int limit, int offset) async {
    return await _odooService.getOrderDetails(orderId, limit, offset);
  }

  Future<QuotationResponse> createQuotation(
    int partnerId,
    List<Map<String, dynamic>> orderLines, {
    String? partnerName,
    bool confirm = false,
  }) async {
    final String offlineRef = "MOB-SO-${DateTime.now().millisecondsSinceEpoch}";

    if (await isOnlineMode()) {
      try {
        final result = await _odooService
            .postRPC(OdooService.saleQuotationCreate, {
              "partner_id": partnerId,
              "offline_ref": offlineRef,
              "confirm": confirm,
              "order_lines": orderLines,
            })
            .timeout(const Duration(seconds: 8));

        if (result['status'] == 'success') {
          return QuotationResponse.fromJson(result);
        }
        throw Exception(result['message'] ?? 'Odoo rejected quotation.');
      } catch (_) {
        return await saveOrderLocally(
          actionType: 'sale_order',
          partnerId: partnerId,
          partnerName: partnerName,
          orderLines: orderLines,
          reason: "Server unreachable, queued in SQLite",
        );
      }
    } else {
      return await saveOrderLocally(
        actionType: 'sale_order',
        partnerId: partnerId,
        partnerName: partnerName,
        orderLines: orderLines,
        reason: "Device offline, saved in SQLite",
      );
    }
  }

  // ==================== PURCHASE ORDERS ====================

  Future<List<PurchaseSummary>> fetchPurchaseOrders() async {
    return await _odooService.getPurchaseOrders();
  }

  Future<QuotationResponse> createPurchaseOrder(
    int vendorId,
    List<Map<String, dynamic>> orderLines, {
    String? vendorName,
    bool confirm = false,
  }) async {
    if (await isOnlineMode()) {
      try {
        final result = await _odooService
            .postRPC(OdooService.purchaseOrderCreate, {
              "partner_id": vendorId,
              "confirm": confirm,
              "order_lines": orderLines,
            })
            .timeout(const Duration(seconds: 8));

        if (result['status'] == 'success') {
          return QuotationResponse(
            status: 'success',
            message: result['message'] ?? 'Purchase Order Created',
            orderId: result['po_id'] ?? 0,
            orderName: result['po_name'] ?? '',
            amountTotal: (result['amount_total'] as num?)?.toDouble() ?? 0.0,
          );
        }
        throw Exception(result['message'] ?? 'Failed to create Purchase Order.');
      } catch (_) {
        return await saveOrderLocally(
          actionType: 'purchase_order',
          partnerId: vendorId,
          partnerName: vendorName,
          orderLines: orderLines,
          reason: "Server unreachable, PO queued in SQLite",
        );
      }
    } else {
      return await saveOrderLocally(
        actionType: 'purchase_order',
        partnerId: vendorId,
        partnerName: vendorName,
        orderLines: orderLines,
        reason: "Device offline, PO saved in SQLite",
      );
    }
  }

  // ==================== WAREHOUSE RECEIPTS & DELIVERIES ====================

  Future<List<WarehousePicking>> fetchWarehousePickings(String type) async {
    return await _odooService.getWarehousePickings(type: type);
  }

  Future<PickingDetail> fetchPickingDetails(int pickingId) async {
    return await _odooService.getPickingDetails(pickingId);
  }

  Future<Map<String, dynamic>> validateWarehousePicking(
    int pickingId,
    List<PickingMoveLine> moves,
  ) async {
    final movePayload = moves.map((m) => {"move_id": m.moveId, "qty_done": m.doneQty}).toList();
    return await _odooService.validatePicking(pickingId: pickingId, moves: movePayload);
  }

  // ==================== SQLITE OFFLINE QUEUE ====================

  Future<QuotationResponse> saveOrderLocally({
    required String actionType,
    required int partnerId,
    String? partnerName,
    required List<Map<String, dynamic>> orderLines,
    required String reason,
  }) async {
    final String draftId = DateTime.now().millisecondsSinceEpoch.toString();
    final String prefix = actionType == 'purchase_order' ? 'PO-DRAFT' : 'SO-DRAFT';
    final String draftName = "$prefix-$draftId";

    await _localDb.enqueueOfflineAction(
      id: draftId,
      actionType: actionType,
      partnerId: partnerId,
      partnerName: partnerName,
      payload: {"partner_id": partnerId, "order_lines": orderLines},
    );

    return QuotationResponse(
      status: "offline_success",
      message: "$reason ($draftName)",
      orderId: 0,
      orderName: draftName,
      amountTotal: 0.0,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingOfflineDrafts() async {
    return await _localDb.getPendingQueue();
  }

  Future deleteOfflineDraft(String draftId) async {
    await _localDb.deleteQueueItem(draftId);
  }

  Future synchronizeOfflineQueue() async {
    if (!await isOnlineMode()) {
      throw Exception("No internet connection detected. Please verify network status.");
    }
    final pending = await _localDb.getPendingQueue();
    if (pending.isEmpty) return 0;
    int syncedCount = 0;
    for (final item in pending) {
      if (!await _connectionChecker.hasConnection) {
        throw Exception("Network dropped midway during queue synchronization.");
      }
      final String id = item['id'].toString();
      final String actionType = item['action_type']?.toString() ?? 'sale_order';
      final int partnerId = item['partner_id'] as int;
      final List<Map<String, dynamic>> orderLines = (item['order_lines'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      try {
        final String endpoint = actionType == 'purchase_order'
            ? OdooService.purchaseOrderCreate
            : OdooService.saleQuotationCreate;
        final result = await _odooService
            .postRPC(endpoint, {
              "partner_id": partnerId,
              "offline_ref": "MOB-$id",
              "order_lines": orderLines,
            })
            .timeout(const Duration(seconds: 6));
        if (result['status'] == 'success') {
          await _localDb.deleteQueueItem(id);
          syncedCount++;
        } else {
          throw Exception("Odoo Validation Error: ${result['message'] ?? 'Unknown failure.'}");
        }
      } on TimeoutException {
        throw Exception("Odoo server timed out. Halting queue processing.");
      } on SocketException {
        throw Exception("Server is unreachable. Check your connection.");
      }
    }
    return syncedCount;
  }
}
