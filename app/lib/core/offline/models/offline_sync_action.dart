enum OfflineSyncActionType {
  saveProductSetup,
  createProductionEntry,
  createSaleDispatch,
  createSaleWithFinance,
  attachFinance,
  recordPayment,
  createExpenseEntry,
}

class OfflineSyncAction {
  const OfflineSyncAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final OfflineSyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory OfflineSyncAction.fromMap(Map<String, dynamic> map) {
    return OfflineSyncAction(
      id: map['id'] as String,
      type: OfflineSyncActionType.values.byName(map['type'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
