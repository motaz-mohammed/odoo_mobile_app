class WarehousePicking {
  final int id;
  final String name;
  final String partnerName;
  final String origin;
  final String scheduledDate;
  final String state;

  WarehousePicking({
    required this.id,
    required this.name,
    required this.partnerName,
    required this.origin,
    required this.scheduledDate,
    required this.state,
  });

  factory WarehousePicking.fromJson(Map<String, dynamic> json) {
    return WarehousePicking(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      partnerName: json['partner_name'] ?? '',
      origin: json['origin'] ?? '',
      scheduledDate: json['scheduled_date'] ?? '',
      state: json['state'] ?? 'assigned',
    );
  }
}

class PickingMoveLine {
  final int moveId;
  final int productId;
  final String productName;
  final String barcode;
  final double demandQty;
  double doneQty;
  final String uom;

  PickingMoveLine({
    required this.moveId,
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.demandQty,
    required this.doneQty,
    required this.uom,
  });

  factory PickingMoveLine.fromJson(Map<String, dynamic> json) {
    return PickingMoveLine(
      moveId: json['move_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      barcode: json['barcode'] ?? '',
      demandQty: (json['demand_qty'] as num?)?.toDouble() ?? 0.0,
      doneQty: (json['done_qty'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom'] ?? 'Units',
    );
  }
}

class PickingDetail {
  final int pickingId;
  final String name;
  final String origin;
  final String partnerName;
  final String state;
  final List<PickingMoveLine> moves;

  PickingDetail({
    required this.pickingId,
    required this.name,
    required this.origin,
    required this.partnerName,
    required this.state,
    required this.moves,
  });

  factory PickingDetail.fromJson(Map<String, dynamic> json) {
    final rawMoves = json['moves'] as List? ?? [];
    return PickingDetail(
      pickingId: json['picking_id'] ?? 0,
      name: json['name'] ?? '',
      origin: json['origin'] ?? '',
      partnerName: json['partner_name'] ?? '',
      state: json['state'] ?? '',
      moves: rawMoves
          .map((m) => PickingMoveLine.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList(),
    );
  }
}
