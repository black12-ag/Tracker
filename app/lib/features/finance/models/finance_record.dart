class FinanceRecord {
  const FinanceRecord({
    required this.id,
    required this.dispatchId,
    required this.customerName,
    required this.sizeLabel,
    required this.sizeLiters,
    required this.quantityUnits,
    required this.soldAt,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.unitPriceSnapshot,
    required this.unitCostSnapshot,
    required this.financeStatus,
    this.loanLabel,
  });

  final String id;
  final String dispatchId;
  final String customerName;
  final String sizeLabel;
  final double sizeLiters;
  final int quantityUnits;
  final DateTime soldAt;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final double unitPriceSnapshot;
  final double unitCostSnapshot;
  final String financeStatus;
  final String? loanLabel;

  factory FinanceRecord.fromMap(Map<String, dynamic> map) {
    return FinanceRecord(
      id: map['id'] as String,
      dispatchId: map['dispatch_id'] as String,
      customerName: map['customer_name'] as String? ?? '',
      sizeLabel: map['size_label'] as String? ?? '',
      sizeLiters: (map['size_liters'] as num?)?.toDouble() ?? 0,
      quantityUnits: map['quantity_units'] as int? ?? 0,
      soldAt:
          DateTime.tryParse(map['sold_at'] as String? ?? '') ?? DateTime.now(),
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      balanceAmount: (map['balance_amount'] as num?)?.toDouble() ?? 0,
      unitPriceSnapshot: (map['unit_price_snapshot'] as num?)?.toDouble() ?? 0,
      unitCostSnapshot: (map['unit_cost_snapshot'] as num?)?.toDouble() ?? 0,
      financeStatus: map['finance_status'] as String? ?? 'unpaid',
      loanLabel: map['loan_label'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dispatch_id': dispatchId,
      'customer_name': customerName,
      'size_label': sizeLabel,
      'size_liters': sizeLiters,
      'quantity_units': quantityUnits,
      'sold_at': soldAt.toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'unit_price_snapshot': unitPriceSnapshot,
      'unit_cost_snapshot': unitCostSnapshot,
      'finance_status': financeStatus,
      'loan_label': loanLabel,
    };
  }
}
