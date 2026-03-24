class ProductionEntryModel {
  const ProductionEntryModel({
    required this.id,
    required this.producedOn,
    required this.quantityUnits,
    required this.sizeLabel,
    required this.sizeLiters,
    this.notes,
  });

  final String id;
  final DateTime producedOn;
  final int quantityUnits;
  final String sizeLabel;
  final double sizeLiters;
  final String? notes;

  factory ProductionEntryModel.fromMap(Map<String, dynamic> map) {
    return ProductionEntryModel(
      id: map['id'] as String,
      producedOn:
          DateTime.tryParse(map['produced_on'] as String? ?? '') ??
          DateTime.now(),
      quantityUnits: map['quantity_units'] as int? ?? 0,
      sizeLabel: map['size_label'] as String? ?? '',
      sizeLiters: (map['size_liters'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produced_on': producedOn.toIso8601String(),
      'quantity_units': quantityUnits,
      'size_label': sizeLabel,
      'size_liters': sizeLiters,
      'notes': notes,
    };
  }
}
