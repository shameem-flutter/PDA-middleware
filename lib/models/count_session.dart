class CountingSession {
  final int? id;
  final int productId;
  final int countedQuantity;
  final String? productName;
  final String? sku;
  final int? erpQuantity;
  final DateTime? timestamp;
  final String? status;

  CountingSession({
    this.id,
    required this.productId,
    required this.countedQuantity,
    this.productName,
    this.sku,
    this.erpQuantity = 0,
    this.timestamp,
    this.status,
  });

  factory CountingSession.fromMap(Map<String, dynamic> map) {
    return CountingSession(
      id: map['id'] as int?,
      productId: int.tryParse(map['productId'].toString()) ?? 0,
      productName: map['productName'] as String?,
      sku: map['sku'] as String?,
      erpQuantity: int.tryParse(map['erpQuantity']?.toString() ?? '0') ?? 0,
      countedQuantity: int.tryParse(map['countedQuantity'].toString()) ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString())
          : null,
      status: map['status'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'countedQuantity': countedQuantity,
      'erpQuantity': erpQuantity,
      'timestamp': timestamp?.toIso8601String(),
      'status': status,
    };
  }

  CountingSession copyWith({
    int? id,
    int? productId,
    int? countedQuantity,
    String? productName,
    String? sku,
    int? erpQuantity,
    DateTime? timestamp,
    String? status,
  }) {
    return CountingSession(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      countedQuantity: countedQuantity ?? this.countedQuantity,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      erpQuantity: erpQuantity ?? this.erpQuantity,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
