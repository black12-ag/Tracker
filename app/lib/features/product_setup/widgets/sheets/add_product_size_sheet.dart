import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/buttons/save_product_size_button.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/custom_size_label_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/custom_size_liters_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/custom_size_low_stock_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/custom_size_unit_price_field.dart';

class AddProductSizeDraft {
  const AddProductSizeDraft({
    required this.label,
    required this.liters,
    required this.lowStockThreshold,
    required this.unitPrice,
  });

  final String label;
  final double liters;
  final int lowStockThreshold;
  final double? unitPrice;
}

class AddProductSizeSheet extends StatefulWidget {
  const AddProductSizeSheet({required this.existingSizes, super.key});

  final List<ProductSizeSetting> existingSizes;

  @override
  State<AddProductSizeSheet> createState() => _AddProductSizeSheetState();
}

class _AddProductSizeSheetState extends State<AddProductSizeSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _litersController;
  late final TextEditingController _priceController;
  late final TextEditingController _lowStockController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _litersController = TextEditingController();
    _priceController = TextEditingController();
    _lowStockController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    final label = _labelController.text.trim();
    final liters = double.tryParse(_litersController.text.trim()) ?? 0;
    final priceText = _priceController.text.trim();
    final unitPrice = priceText.isEmpty ? null : double.tryParse(priceText);
    final lowStock = int.tryParse(_lowStockController.text.trim()) ?? -1;

    if (label.isEmpty) {
      _showError('Enter a size label.');
      return;
    }
    if (liters <= 0) {
      _showError('Enter a valid liters value.');
      return;
    }
    if (unitPrice != null && unitPrice < 0) {
      _showError('Enter a valid unit price.');
      return;
    }
    if (lowStock < 0) {
      _showError('Enter a valid low stock alert.');
      return;
    }

    final duplicateLabel = widget.existingSizes.any(
      (size) => size.label.trim().toLowerCase() == label.toLowerCase(),
    );
    if (duplicateLabel) {
      _showError('This size label already exists.');
      return;
    }

    final duplicateLiters = widget.existingSizes.any(
      (size) => (size.liters - liters).abs() < 0.001,
    );
    if (duplicateLiters) {
      _showError('This liters size already exists.');
      return;
    }

    Navigator.of(context).pop(
      AddProductSizeDraft(
        label: label,
        liters: liters,
        lowStockThreshold: lowStock,
        unitPrice: unitPrice,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: AppSurfaceCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'Add size',
                  subtitle: 'Create another pack size for the same product.',
                ),
                const SizedBox(height: 16),
                CustomSizeLabelField(controller: _labelController),
                const SizedBox(height: 12),
                CustomSizeLitersField(controller: _litersController),
                const SizedBox(height: 12),
                CustomSizeUnitPriceField(controller: _priceController),
                const SizedBox(height: 12),
                CustomSizeLowStockField(controller: _lowStockController),
                const SizedBox(height: 18),
                SaveProductSizeButton(onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
