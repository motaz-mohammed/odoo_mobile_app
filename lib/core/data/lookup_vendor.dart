class VendorLookup {
  final int id;
  final String name;
  final String email;
  final String phone;

  VendorLookup({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory VendorLookup.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null || value is bool) return '';
      return value.toString();
    }

    return VendorLookup(
      id: json['id'] ?? 0,
      name: safeString(json['name']),
      email: safeString(json['email']),
      phone: safeString(json['phone']),
    );
  }
}
