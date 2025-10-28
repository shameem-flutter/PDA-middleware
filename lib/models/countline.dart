class CountLine {
  final int? id;
  final int productId;
  final int sessionId;
  final int countedQuantity;

  CountLine({
    this.id,
    required this.productId,
    required this.sessionId,
    required this.countedQuantity,
  });

  factory CountLine.fromMap(Map<String, dynamic> map) {
    return CountLine(
      id: map['id'],
      productId: map['productId'],
      sessionId: map['sessionId'],
      countedQuantity: map['countedQuantity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'sessionId': sessionId,
      'countedQuantity': countedQuantity,
    };
  }
}
