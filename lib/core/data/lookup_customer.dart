class CustomerLookup {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final int? zoneId;
  final String zoneName;

  CustomerLookup({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.city = '',
    this.zoneId,
    this.zoneName = '',
  });

  factory CustomerLookup.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null || value is bool) return '';
      return value.toString();
    }

    int? parsedZoneId = json['zone_id'] as int?;
    String parsedZoneName = safeString(json['zone_name']);

    if (json['mobile_zone_id'] is List && (json['mobile_zone_id'] as List).length >= 2) {
      parsedZoneId = (json['mobile_zone_id'] as List)[0] as int?;
      parsedZoneName = (json['mobile_zone_id'] as List)[1]?.toString() ?? '';
    }

    return CustomerLookup(
      id: json['id'] ?? 0,
      name: safeString(json['name']),
      email: safeString(json['email']),
      phone: safeString(json['phone']),
      city: safeString(json['city']),
      zoneId: parsedZoneId,
      zoneName: parsedZoneName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'zone_id': zoneId,
      'zone_name': zoneName,
    };
  }
}
