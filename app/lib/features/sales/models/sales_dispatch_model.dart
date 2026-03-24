import 'package:liquid_soap_tracker/features/sales/models/customer_model.dart';

class SalesDispatchModel {
  const SalesDispatchModel({
    required this.id,
    required this.customer,
    required this.sizeId,
    required this.sizeLabel,
    required this.sizeLiters,
    required this.quantityUnits,
    required this.soldAt,
    required this.dispatchStatus,
    this.notes,
    this.financeStatus,
    this.totalAmount,
    this.balanceAmount,
  });

  final String id;
  final CustomerModel customer;
  final String sizeId;
  final String sizeLabel;
  final double sizeLiters;
  final int quantityUnits;
  final DateTime soldAt;
  final String dispatchStatus;
  final String? notes;
  final String? financeStatus;
  final double? totalAmount;
  final double? balanceAmount;

  factory SalesDispatchModel.fromMap(Map<String, dynamic> map) {
    return SalesDispatchModel(
      id: map['id'] as String,
      customer: CustomerModel.fromMap(
        Map<String, dynamic>.from(map['customer'] as Map),
      ),
      sizeId: map['size_id'] as String,
      sizeLabel: map['size_label'] as String? ?? '',
      sizeLiters: (map['size_liters'] as num?)?.toDouble() ?? 0,
      quantityUnits: map['quantity_units'] as int? ?? 0,
      soldAt:
          DateTime.tryParse(map['sold_at'] as String? ?? '') ?? DateTime.now(),
      dispatchStatus: map['dispatch_status'] as String? ?? 'recorded',
      notes: map['notes'] as String?,
      financeStatus: map['finance_status'] as String?,
      totalAmount: (map['total_amount'] as num?)?.toDouble(),
      balanceAmount: (map['balance_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer': customer.toMap(),
      'size_id': sizeId,
      'size_label': sizeLabel,
      'size_liters': sizeLiters,
      'quantity_units': quantityUnits,
      'sold_at': soldAt.toIso8601String(),
      'dispatch_status': dispatchStatus,
      'notes': notes,
      'finance_status': financeStatus,
      'total_amount': totalAmount,
      'balance_amount': balanceAmount,
    };
  }
}
