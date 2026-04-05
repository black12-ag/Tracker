import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/layout/app_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/app_loading_view.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/app_section_title.dart';
import 'package:liquid_soap_tracker/core/utils/display_cleaner.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/dashboard/controller/dashboard_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/controller/product_setup_controller.dart';
import 'package:liquid_soap_tracker/features/product_setup/models/product_setup_bundle.dart';
import 'package:liquid_soap_tracker/features/production/controller/production_controller.dart';
import 'package:liquid_soap_tracker/features/production/models/production_entry_model.dart';
import 'package:liquid_soap_tracker/features/production/widgets/buttons/save_production_button.dart';
import 'package:liquid_soap_tracker/features/production/widgets/sections/production_form_section.dart';
import 'package:liquid_soap_tracker/features/production/widgets/sheets/production_entry_detail_sheet.dart';

class ProductionPage extends ConsumerStatefulWidget {
  const ProductionPage({required this.profile, super.key});

  final AppProfile profile;

  @override
  ConsumerState<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends ConsumerState<ProductionPage> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedSizeId;
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save(String userId, List<ProductSizeSetting> sizes) async {
    final sizeId = _selectedSizeId;
    final quantityUnits = int.tryParse(_quantityController.text.trim()) ?? 0;

    if (sizeId == null || quantityUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a size and enter a valid quantity.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await ref
          .read(productionRepositoryProvider)
          .createEntry(
            producedOn: _selectedDate,
            sizeId: sizeId,
            quantityUnits: quantityUnits,
            notes: _notesController.text,
            createdBy: userId,
            sizeLabel: sizes.firstWhere((size) => size.id == sizeId).label,
            sizeLiters: sizes.firstWhere((size) => size.id == sizeId).liters,
          );
      await ref.read(offlineSyncServiceProvider).refreshPendingCount();

      ref
        ..invalidate(productionEntriesProvider)
        ..invalidate(productSetupBundleProvider)
        ..invalidate(dashboardBundleProvider);

      _quantityController.clear();
      _notesController.clear();
      setState(() => _selectedDate = DateTime.now());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showDetails(BuildContext context, ProductionEntryModel entry) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (context) => ProductionEntryDetailSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync = ref.watch(productSetupBundleProvider);
    final entriesAsync = ref.watch(productionEntriesProvider);

    return AppPageScaffold(
      title: 'Production',
      subtitle: 'Add what was made today.',
      child: bundleAsync.when(
        data: (bundle) {
          _selectedSizeId ??= bundle.sizes.firstOrNull?.id;
          return Column(
            children: [
              ProductionFormSection(
                selectedDate: _selectedDate,
                onPickDate: _pickDate,
                selectedSizeId: _selectedSizeId,
                onChangedSize: (value) =>
                    setState(() => _selectedSizeId = value),
                sizeOptions: bundle.sizes,
                quantityController: _quantityController,
                notesController: _notesController,
              ),
              const SizedBox(height: 18),
              SaveProductionButton(
                onPressed: () => _save(widget.profile.id, bundle.sizes),
                isBusy: _isSaving,
              ),
              const SizedBox(height: 18),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionTitle(
                      title: 'Recent production',
                      subtitle: 'Tap any row to see more',
                    ),
                    const SizedBox(height: 14),
                    entriesAsync.when(
                      data: (entries) {
                        if (entries.isEmpty) {
                          return Text(
                            'No production has been recorded yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }

                        return Column(
                          children: entries
                              .map(
                                (entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () => _showDetails(context, entry),
                                  title: Text(
                                    '${entry.sizeLabel} • ${entry.quantityUnits} units',
                                  ),
                                  subtitle: Text(
                                    '${AppFormatters.date(entry.producedOn)} • ${AppFormatters.liters(entry.sizeLiters)}',
                                  ),
                                  trailing:
                                      DisplayCleaner.note(entry.notes) != null
                                      ? const Icon(Icons.chevron_right_rounded)
                                      : null,
                                ),
                              )
                              .toList(),
                        );
                      },
                      loading: () => const AppLoadingView(
                        message: 'Loading production history...',
                      ),
                      error: (error, stackTrace) => Text(error.toString()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 220,
          child: AppLoadingView(message: 'Loading production setup...'),
        ),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }
}
