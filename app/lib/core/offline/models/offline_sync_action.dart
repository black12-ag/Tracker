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
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final OfflineSyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  /// How many times syncing this action has been attempted and failed.
  /// Used to give up on poison messages instead of retrying forever.
  final int attempts;

  /// Human-readable reason the last attempt failed (kept for the dead-letter
  /// queue so the failure is never silent).
  final String? lastError;

  OfflineSyncAction copyWith({int? attempts, String? lastError}) {
    return OfflineSyncAction(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  factory OfflineSyncAction.fromMap(Map<String, dynamic> map) {
    return OfflineSyncAction(
      id: map['id'] as String,
      type: OfflineSyncActionType.values.byName(map['type'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    };
  }
}
