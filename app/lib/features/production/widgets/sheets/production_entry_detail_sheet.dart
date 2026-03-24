import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';

class ProductionEntryDetailSheet extends StatelessWidget {
  const ProductionEntryDetailSheet({required this.entry, super.key});

  final ProductionEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final note = DisplayCleaner.note(entry.notes);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Production details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Size'),
              subtitle: Text(entry.sizeLabel),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quantity'),
              subtitle: Text(AppFormatters.units(entry.quantityUnits)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(AppFormatters.dateTime(entry.producedOn)),
            ),
            if (note != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notes'),
                subtitle: Text(note),
              ),
          ],
        ),
      ),
    );
  }
}
