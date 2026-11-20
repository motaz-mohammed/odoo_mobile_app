class GeographicZone {
  final int id;
  final String name;
  final String code;

  GeographicZone({required this.id, required this.name, required this.code});

  factory GeographicZone.fromJson(Map<String, dynamic> json) {
    return GeographicZone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'code': code};
}

class UserSession {
  final int uid;
  final String name;
  final String companyName;
  final String currency;
  final List<GeographicZone> zones;
  final bool isSales;
  final bool isPurchase;
  final bool isWarehouse;

  UserSession({
    required this.uid,
    required this.name,
    required this.companyName,
    required this.currency,
    required this.zones,
    required this.isSales,
    required this.isPurchase,
    required this.isWarehouse,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final ctx = json['user_context'] as Map<String, dynamic>? ?? {};
    final perms = json['permissions'] as Map<String, dynamic>? ?? {};
    final rawZones = json['zones'] as List? ?? [];

    return UserSession(
      uid: json['uid'] ?? 0,
      name: json['name'] ?? 'Mobile User',
      companyName: ctx['company_name'] ?? '',
      currency: ctx['currency'] ?? '\$',
      zones: rawZones
          .map((z) => GeographicZone.fromJson(Map<String, dynamic>.from(z as Map)))
          .toList(),
      isSales: perms['is_sales'] == true,
      isPurchase: perms['is_purchase'] == true,
      isWarehouse: perms['is_warehouse'] == true,
    );
  }
}
