import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/app/theme/app_motion.dart';
import 'package:tracker/core/models/app_profile.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/core/ui/cards/app_surface_card.dart';
import 'package:tracker/core/ui/fields/app_text_field.dart';
import 'package:tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:tracker/core/ui/rows/inventory_row.dart';
import 'package:tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:tracker/core/ui/widgets/filter_chips.dart';
import 'package:tracker/core/utils/app_errors.dart';
import 'package:tracker/features/inventory/page/inventory_item_page.dart';

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
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _matches(Map<String, dynamic> item) {
    if (_filter == 'all') {
      return true;
    }
    final stock = (item['current_stock'] as num?)?.toInt() ?? 0;
    final threshold = (item['low_stock'] as num?)?.toInt() ?? 10;
    switch (_filter) {
      case 'in':
        return stock > threshold;
      case 'low':
        return stock > 0 && stock <= threshold;
      case 'out':
        return stock <= 0;
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> items) {
    return items.where(_matches).toList();
  }

  int _countFor(String value) {
    final saved = _filter;
    _filter = value;
    final count = _items.where(_matches).length;
    _filter = saved;
    return count;
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
    final visible = _applyFilter(_items);
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
          const SizedBox(height: 8),
          FilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            options: [
              FilterChipOption('all', 'All', count: _countFor('all')),
              FilterChipOption('in', 'In stock', count: _countFor('in')),
              FilterChipOption('low', 'Low stock', count: _countFor('low')),
              FilterChipOption('out', 'Out of stock', count: _countFor('out')),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(itemCount: 5)
          else if (visible.isEmpty)
            const _InventoryEmptyState()
          else
            AppSurfaceCard(
              child: Column(
                children: visible.indexed.map((entry) {
                  final index = entry.$1;
                  final item = entry.$2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StaggeredListItem(
                        index: index,
                        child: InventoryRow(
                          name: item['name'] as String? ?? '',
                          sku: item['sku'] as String? ?? '',
                          unitType: item['unit_type'] as String? ?? '',
                          stockQty: (item['current_stock'] as num?)?.toInt() ?? 0,
                          price: (item['selling_price'] as num?)?.toDouble() ?? 0,
                          onTap: () => _openItem(item),
                        ),
                      ),
                      if (index < visible.length - 1)
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

/// Consistent empty state for the inventory list.
class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 44, color: AppColors.warmGray),
          const SizedBox(height: 12),
          Text(
            'No items yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first product to start tracking stock.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.warmGray,
                ),
          ),
        ],
      ),
    );
  }
}

/// Subtle staggered fade + rise entrance for list rows. Honours reduced motion
/// (renders the row instantly with no offset).
class _StaggeredListItem extends StatelessWidget {
  const _StaggeredListItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.noAnimations(context)) {
      return child;
    }
    final delay = AppMotion.listStaggerStep * index;
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.listItemFade + delay,
      curve: Interval(
        (delay.inMilliseconds /
                (AppMotion.listItemFade + delay).inMilliseconds)
            .clamp(0.0, 1.0),
        1,
        curve: AppMotion.enter,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
