import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/rows/inventory_row.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/app_errors.dart';
import 'package:liquid_soap_tracker/features/inventory/page/inventory_item_page.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await ref.read(trackerRepositoryProvider).listInventoryItems(
            search: _searchController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.humanize(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openItem([Map<String, dynamic>? item]) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => InventoryItemPage(
          profile: widget.profile,
          existingItem: item,
        ),
      ),
    );

    if (result != null) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Inventory',
      onMenuPressed: widget.onMenuPressed,
      showBottomNavigation: false,
      floatingActionButton: FloatingActionButton(
        onPressed: _openItem,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _searchController,
            label: 'Search inventory',
            hintText: 'Search by item name or SKU',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => _load(),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(itemCount: 5)
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.warmGray),
                  const SizedBox(height: 12),
                  Text(
                    'No inventory items found.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            AppSurfaceCard(
              child: Column(
                children: _items.indexed.map((entry) {
                  final index = entry.$1;
                  final item = entry.$2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InventoryRow(
                        name: item['name'] as String? ?? '',
                        sku: item['sku'] as String? ?? '',
                        unitType: item['unit_type'] as String? ?? '',
                        stockQty: (item['current_stock'] as num?)?.toInt() ?? 0,
                        price: (item['selling_price'] as num?)?.toDouble() ?? 0,
                        onTap: () => _openItem(item),
                      ),
                      if (index < _items.length - 1)
                        const Divider(height: 1, color: AppColors.line, thickness: 0.8),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
