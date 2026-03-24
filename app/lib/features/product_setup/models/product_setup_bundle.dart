class ProductSetupBundle {
  const ProductSetupBundle({
    required this.productName,
    required this.defaultCostPerLiter,
    required this.sizes,
    required this.canSeeFinancials,
    this.productImagePath,
    this.productImageUrl,
  });

  final String productName;
  final double? defaultCostPerLiter;
  final List<ProductSizeSetting> sizes;
  final bool canSeeFinancials;
  final String? productImagePath;
  final String? productImageUrl;

  factory ProductSetupBundle.fromMap(Map<String, dynamic> map) {
    return ProductSetupBundle(
      productName: map['product_name'] as String? ?? 'Liquid Soap',
      defaultCostPerLiter: (map['default_cost_per_liter'] as num?)?.toDouble(),
      productImagePath: map['product_image_path'] as String?,
      productImageUrl: map['product_image_url'] as String?,
      sizes: ((map['sizes'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                ProductSizeSetting.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      canSeeFinancials: map['can_see_financials'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_name': productName,
      'default_cost_per_liter': defaultCostPerLiter,
      'product_image_path': productImagePath,
      'product_image_url': productImageUrl,
      'sizes': sizes.map((size) => size.toMap()).toList(),
      'can_see_financials': canSeeFinancials,
    };
  }
}

class ProductSizeSetting {
  const ProductSizeSetting({
    required this.id,
    required this.label,
    required this.liters,
    required this.lowStockThreshold,
    required this.active,
    this.unitPrice,
    this.producedUnits = 0,
    this.soldUnits = 0,
    this.currentStockUnits = 0,
    this.isLowStock = false,
  });

  final String id;
  final String label;
  final double liters;
  final int lowStockThreshold;
  final bool active;
  final double? unitPrice;
  final int producedUnits;
  final int soldUnits;
  final int currentStockUnits;
  final bool isLowStock;

  ProductSizeSetting copyWith({
    int? lowStockThreshold,
    bool? active,
    double? unitPrice,
    int? producedUnits,
    int? soldUnits,
    int? currentStockUnits,
    bool? isLowStock,
  }) {
    return ProductSizeSetting(
      id: id,
      label: label,
      liters: liters,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      active: active ?? this.active,
      unitPrice: unitPrice ?? this.unitPrice,
      producedUnits: producedUnits ?? this.producedUnits,
      soldUnits: soldUnits ?? this.soldUnits,
      currentStockUnits: currentStockUnits ?? this.currentStockUnits,
      isLowStock: isLowStock ?? this.isLowStock,
    );
  }

  factory ProductSizeSetting.fromMap(Map<String, dynamic> map) {
    return ProductSizeSetting(
      id: map['id'] as String,
      label: map['label'] as String? ?? '',
      liters: (map['liters'] as num?)?.toDouble() ?? 0,
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 0,
      active: map['active'] as bool? ?? true,
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      producedUnits: map['produced_units'] as int? ?? 0,
      soldUnits: map['sold_units'] as int? ?? 0,
      currentStockUnits: map['current_stock_units'] as int? ?? 0,
      isLowStock: map['is_low_stock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'liters': liters,
      'low_stock_threshold': lowStockThreshold,
      'active': active,
      'unit_price': unitPrice,
      'produced_units': producedUnits,
      'sold_units': soldUnits,
      'current_stock_units': currentStockUnits,
      'is_low_stock': isLowStock,
    };
  }
}
