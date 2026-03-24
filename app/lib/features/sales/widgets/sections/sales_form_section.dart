import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/customer_name_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/customer_phone_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/sales_amount_paid_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/sales_loan_label_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/sales_notes_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/sales_quantity_field.dart';
import 'package:liquid_soap_tracker/features/sales/widgets/fields/sales_unit_price_field.dart';

class SalesFormSection extends StatelessWidget {
  const SalesFormSection({
    required this.sizeOptions,
    required this.selectedSizeId,
    required this.onChangedSize,
    required this.customerNameController,
    required this.customerPhoneController,
    required this.quantityController,
    required this.notesController,
    required this.isOwner,
    required this.unitPriceController,
    required this.amountPaidController,
    required this.loanLabelController,
    required this.showLoanLabel,
    super.key,
  });

  final List<ProductSizeSetting> sizeOptions;
  final String? selectedSizeId;
  final ValueChanged<String?> onChangedSize;
  final TextEditingController customerNameController;
  final TextEditingController customerPhoneController;
  final TextEditingController quantityController;
  final TextEditingController notesController;
  final bool isOwner;
  final TextEditingController unitPriceController;
  final TextEditingController amountPaidController;
  final TextEditingController loanLabelController;
  final bool showLoanLabel;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'New sale',
            subtitle: isOwner
                ? 'Add the sale and money paid now.'
                : 'Add the customer and quantity only.',
          ),
          const SizedBox(height: 16),
          CustomerNameField(controller: customerNameController),
          const SizedBox(height: 12),
          CustomerPhoneField(controller: customerPhoneController),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedSizeId,
            decoration: const InputDecoration(
              labelText: 'Pack size',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: sizeOptions
                .map(
                  (size) => DropdownMenuItem(
                    value: size.id,
                    child: Text(
                      '${size.label} (${AppFormatters.liters(size.liters)})',
                    ),
                  ),
                )
                .toList(),
            onChanged: onChangedSize,
          ),
          const SizedBox(height: 12),
          SalesQuantityField(controller: quantityController),
          const SizedBox(height: 12),
          SalesNotesField(controller: notesController),
          if (isOwner) ...[
            const SizedBox(height: 12),
            SalesUnitPriceField(controller: unitPriceController),
            const SizedBox(height: 12),
            SalesAmountPaidField(controller: amountPaidController),
            if (showLoanLabel) ...[
              const SizedBox(height: 12),
              SalesLoanLabelField(controller: loanLabelController),
            ],
          ],
        ],
      ),
    );
  }
}
