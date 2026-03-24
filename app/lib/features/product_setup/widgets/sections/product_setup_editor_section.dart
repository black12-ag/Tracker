import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/buttons/add_product_size_button.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/buttons/upload_product_image_button.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/default_cost_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/low_stock_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/product_name_field.dart';
import 'package:liquid_soap_tracker/features/product_setup/widgets/fields/size_price_field.dart';

class ProductSetupEditorSection extends StatelessWidget {
  const ProductSetupEditorSection({
    required this.sizes,
    required this.productNameController,
    required this.defaultCostController,
    required this.priceControllers,
    required this.lowStockControllers,
    required this.readOnly,
    required this.productImageUrl,
    this.onUploadImage,
    this.onAddSize,
    this.isUploadingImage = false,
    super.key,
  });

  final List<ProductSizeSetting> sizes;
  final TextEditingController productNameController;
  final TextEditingController defaultCostController;
  final Map<String, TextEditingController> priceControllers;
  final Map<String, TextEditingController> lowStockControllers;
  final bool readOnly;
  final String? productImageUrl;
  final VoidCallback? onUploadImage;
  final VoidCallback? onAddSize;
  final bool isUploadingImage;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'Product',
            subtitle: readOnly
                ? 'Photo, sizes, and stock.'
                : 'Photo, sizes, stock, and price when you need it.',
            trailing: !readOnly && onAddSize != null
                ? AddProductSizeButton(onPressed: onAddSize!)
                : null,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Theme.of(context).colorScheme.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: productImageUrl == null || productImageUrl!.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 42),
                      const SizedBox(height: 12),
                      Text(
                        'No product image yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  )
                : Image.network(
                    productImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load product image',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
          ),
          if (!readOnly && onUploadImage != null) ...[
            const SizedBox(height: 16),
            UploadProductImageButton(
              onPressed: onUploadImage!,
              isBusy: isUploadingImage,
            ),
          ],
          const SizedBox(height: 16),
          ProductNameField(
            controller: productNameController,
            readOnly: readOnly,
          ),
          if (!readOnly) ...[
            const SizedBox(height: 16),
            DefaultCostField(
              controller: defaultCostController,
              readOnly: false,
            ),
          ],
          const SizedBox(height: 18),
          ...sizes.map(
            (size) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppSurfaceCard(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      size.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pack size: ${AppFormatters.liters(size.liters)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stock: ${AppFormatters.units(size.currentStockUnits)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (!readOnly) ...[
                      SizePriceField(
                        controller: priceControllers[size.id]!,
                        readOnly: false,
                      ),
                      const SizedBox(height: 12),
                    ],
                    LowStockField(
                      controller: lowStockControllers[size.id]!,
                      readOnly: readOnly,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
