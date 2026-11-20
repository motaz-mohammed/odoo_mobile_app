class ProductLookup {
  final int id;
  final String name;
  final String defaultCode;
  final String barcode;
  final double price;
  final double qtyAvailable;
  final String uomName;
  final String? imageBase64;

  ProductLookup({
    required this.id,
    required this.name,
    this.defaultCode = '',
    this.barcode = '',
    required this.price,
    this.qtyAvailable = 0.0,
    this.uomName = 'Units',
    this.imageBase64,
  });

  factory ProductLookup.fromJson(Map<String, dynamic> json) {
    String safeStr(dynamic v) => (v == null || v is bool) ? '' : v.toString();

    return ProductLookup(
      id: json['id'] ?? 0,
      name: safeStr(json['name']),
      defaultCode: safeStr(json['default_code']),
      barcode: safeStr(json['barcode']),
      price: (json['lst_price'] as num?)?.toDouble() ?? 0.0,
      qtyAvailable: (json['qty_available'] as num?)?.toDouble() ?? 0.0,
      uomName: safeStr(json['uom_name']).isEmpty ? 'Units' : safeStr(json['uom_name']),
      imageBase64: json['image_base64'] ?? json['image'],
    );
  }
}
