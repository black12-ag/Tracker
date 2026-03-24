import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/production/widgets/fields/production_notes_field.dart';
import 'package:liquid_soap_tracker/features/production/widgets/fields/production_quantity_field.dart';

class ProductionFormSection extends StatelessWidget {
  const ProductionFormSection({
    required this.selectedDate,
    required this.onPickDate,
    required this.selectedSizeId,
    required this.onChangedSize,
    required this.sizeOptions,
    required this.quantityController,
    required this.notesController,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;
  final String? selectedSizeId;
  final ValueChanged<String?> onChangedSize;
  final List<ProductSizeSetting> sizeOptions;
  final TextEditingController quantityController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionTitle(
            title: 'Add production',
            subtitle: 'Write what was made today.',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Production date'),
            subtitle: Text(AppFormatters.date(selectedDate)),
            trailing: IconButton(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedSizeId,
            decoration: const InputDecoration(
              labelText: 'Pack size',
              prefixIcon: Icon(Icons.water_drop_outlined),
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
          ProductionQuantityField(controller: quantityController),
          const SizedBox(height: 12),
          ProductionNotesField(controller: notesController),
        ],
      ),
    );
  }
}
