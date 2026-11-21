import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:odoo_mobile_app/core/data/customer_invoice.dart';
import 'package:odoo_mobile_app/core/data/customer_invoice_detail.dart';
import 'package:odoo_mobile_app/core/data/order_detail.dart';
import 'package:odoo_mobile_app/core/data/purchase_detail.dart';
import 'package:odoo_mobile_app/core/data/purchase_summary.dart';
import 'package:odoo_mobile_app/core/data/quotation_data.dart';
import 'package:odoo_mobile_app/core/data/user_session.dart';
import 'package:odoo_mobile_app/core/data/warehouse_picking.dart';
import 'package:odoo_mobile_app/core/helpers/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdooService {
  static const String baseUrl = "http://10.0.2.2:8069";
  static const String defaultDb = "odoo17_test_1";

  // Unified v3 Endpoints
  static const String loginAuth = '/api/v3/auth/login';
  static const String syncMasterData = '/api/v3/sync/master-data';

  // Sales v3
  static const String saleQuotations = '/api/v3/sale/quotations';
  static const String saleQuotationCreate = '/api/v3/sale/quotation/create';
  static const String saleQuotationDetails = '/api/v3/sale/quotation/details';

  // Purchase v3
  static const String purchaseOrders = '/api/v3/purchase/orders';
  static const String purchaseOrderCreate = '/api/v3/purchase/order/create';
  static const String purchaseOrderDetails = '/api/v3/purchase/order/details';

  // Warehouse v3
  static const String warehousePickings = '/api/v3/warehouse/pickings';
  static const String warehousePickingDetails = '/api/v3/warehouse/picking/details';
  static const String warehousePickingValidate = '/api/v3/warehouse/picking/validate';

  static const String _lastSyncKey = 'odoo_last_master_sync';
  static const String _userProfileKey = 'odoo_user_profile_json';

  static const String customerInvoices = '/api/v3/account/invoices';
  static const String registerInvoicePayment = '/api/v3/account/invoice/pay';
  static const String customerInvoiceDetails = '/api/v3/account/invoice/details';
  static const String createCustomerInvoiceEndpoint = '/api/v3/account/invoice/create';

  Future<String?> _getSavedSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(odooSessionId);
  }

  Future<bool> saveSessionId(String sessionToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(odooSessionId, sessionToken);
    return hasSavedSession();
  }

  Future<bool> hasSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? session = prefs.getString(odooSessionId);
    return session != null && session.isNotEmpty;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(odooSessionId);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_userProfileKey);
  }

  Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  Future<void> saveLastSyncTimestamp(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, timestamp);
  }

  Future<void> saveUserSessionProfile(Map<String, dynamic> rawLoginResult) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, jsonEncode(rawLoginResult));
  }

  Future<UserSession?> getSavedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Generic JSON-RPC POST Handler
  Future<dynamic> postRPC(String path, Map<String, dynamic> params) async {
    final sessionId = await _getSavedSessionId();

    final response = await http
        .post(
          Uri.parse("$baseUrl$path"),
          headers: {"Content-Type": "application/json", if (sessionId != null) "Cookie": sessionId},
          body: jsonEncode({"jsonrpc": "2.0", "method": "call", "params": params}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    final body = jsonDecode(response.body);
    if (body.containsKey('error')) {
      final errorMap = body['error'];
      final String errorMessage = errorMap['message'] ?? "Odoo API Error";
      if (errorMessage.toLowerCase().contains("session expired") ||
          errorMessage.toLowerCase().contains("session_expired")) {
        throw Exception("SESSION_EXPIRED");
      }
      throw Exception(errorMessage);
    }

    return body['result'];
  }

  // ==================== 1. AUTH LOGIN ====================
  Future<UserSession> login(String user, String pass, {String? db}) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl$loginAuth"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "jsonrpc": "2.0",
            "method": "call",
            "params": {
              "db": (db != null && db.isNotEmpty) ? db : defaultDb,
              "login": user,
              "password": pass,
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body);
    final result = body['result'] as Map<String, dynamic>?;

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Invalid login credentials.");
    }

    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      final sessionToken = rawCookie
          .split(';')
          .firstWhere(
            (element) => element.trim().startsWith('session_id='),
            orElse: () => rawCookie.split(';').first,
          );
      await saveSessionId(sessionToken);
    } else if (result['session_id'] != null) {
      await saveSessionId("session_id=${result['session_id']}");
    }

    await saveUserSessionProfile(result);
    return UserSession.fromJson(result);
  }

  // ==================== 2. DELTA MASTER DATA SYNC ====================
  Future<Map<String, dynamic>> fetchMasterDataDelta({String? lastSync}) async {
    final result = await postRPC(syncMasterData, {if (lastSync != null) "last_sync": lastSync});

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to sync master data.");
    }
    return Map<String, dynamic>.from(result as Map);
  }

  // ==================== 3. SALES API ====================
  Future<QuotationData> getQuotationData({int limit = 30, int offset = 0}) async {
    final result = await postRPC(saleQuotations, {"limit": limit, "offset": offset});

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to fetch quotations.");
    }

    return QuotationData.fromJson({
      "total_sales_count": result['total_sales_count'] ?? 0,
      "recent_orders": result['data'] ?? [],
    });
  }

  Future<OrderDetail> getOrderDetails(int orderId, int limit, int offset) async {
    final result = await postRPC(saleQuotationDetails, {
      "order_id": orderId,
      "limit": limit,
      "offset": offset,
    });

    if (result == null || result['status'] == 'error') {
      throw Exception(result?['message'] ?? 'Failed to load order details');
    }
    return OrderDetail.fromJson(result);
  }

  // ==================== 4. PURCHASE API ====================
  Future<List<PurchaseSummary>> getPurchaseOrders({int limit = 30, int offset = 0}) async {
    final result = await postRPC(purchaseOrders, {"limit": limit, "offset": offset});

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to fetch purchase orders.");
    }

    final List rawList = result['data'] ?? [];
    return rawList
        .map((e) => PurchaseSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PurchaseDetail> getPurchaseOrderDetails(int poId) async {
    final result = await postRPC(purchaseOrderDetails, {"po_id": poId});
    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to load purchase order details.");
    }
    return PurchaseDetail.fromJson(Map<String, dynamic>.from(result as Map));
  }

  // ==================== 5. WAREHOUSE API ====================
  Future<List<WarehousePicking>> getWarehousePickings({
    required String type, // 'incoming' or 'outgoing'
    int limit = 30,
    int offset = 0,
  }) async {
    final result = await postRPC(warehousePickings, {
      "type": type,
      "limit": limit,
      "offset": offset,
    });

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to fetch warehouse transfers.");
    }

    final List rawList = result['data'] ?? [];
    return rawList
        .map((e) => WarehousePicking.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<PickingDetail> getPickingDetails(int pickingId) async {
    final result = await postRPC(warehousePickingDetails, {"picking_id": pickingId});

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to load transfer details.");
    }
    return PickingDetail.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<Map<String, dynamic>> validatePicking({
    required int pickingId,
    required List<Map<String, dynamic>> moves,
  }) async {
    final result = await postRPC(warehousePickingValidate, {
      "picking_id": pickingId,
      "moves": moves,
    });

    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to validate transfer.");
    }
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<CustomerInvoice>> getCustomerInvoices({String? paymentState}) async {
    final result = await postRPC(customerInvoices, {
      if (paymentState != null) 'payment_state': paymentState,
    });
    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to load invoices.");
    }
    final raw = result['data'] as List? ?? [];
    return raw.map((e) => CustomerInvoice.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Map<String, dynamic>> payCustomerInvoice(int invoiceId, double amount) async {
    final result = await postRPC(registerInvoicePayment, {
      'invoice_id': invoiceId,
      'amount': amount,
    });
    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Payment registration failed.");
    }
    return Map<String, dynamic>.from(result as Map);
  }

  Future<CustomerInvoiceDetail> getCustomerInvoiceDetails(int invoiceId) async {
    final result = await postRPC(customerInvoiceDetails, {'invoice_id': invoiceId});
    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to load invoice details.");
    }
    return CustomerInvoiceDetail.fromJson(Map<String, dynamic>.from(result as Map));
  }

  Future<Map<String, dynamic>> createCustomerInvoice({
    required int partnerId,
    required List<Map<String, dynamic>> lines,
    bool autoPost = true,
  }) async {
    final result = await postRPC(createCustomerInvoiceEndpoint, {
      'partner_id': partnerId,
      'lines': lines,
      'auto_post': autoPost,
    });
    if (result == null || result['status'] != 'success') {
      throw Exception(result?['message'] ?? "Failed to create customer invoice.");
    }
    return Map<String, dynamic>.from(result as Map);
  }
}
