import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/app/theme/app_motion.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/rows/order_row.dart';
import 'package:liquid_soap_tracker/core/ui/widgets/filter_chips.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/app_errors.dart';
import 'package:liquid_soap_tracker/features/sales/page/sales_order_page.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = const [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _statusOf(Map<String, dynamic> row) {
    var status = (row['status'] as String? ?? 'draft').toLowerCase();
    if (status == 'partially_paid') {
      status = 'partial';
    } else if (status == 'canceled') {
      status = 'cancelled';
    }
    return status;
  }

  bool _matches(Map<String, dynamic> row) {
    if (_filter == 'all') {
      return true;
    }
    return _statusOf(row) == _filter;
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> orders) {
    return orders.where(_matches).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ref.read(trackerRepositoryProvider).listSalesOrders(
            search: _searchController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() => _orders = orders);
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

  Future<void> _openCreateOrder() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SalesOrderPage(profile: widget.profile),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _showDetails(Map<String, dynamic> row) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final partner = row['partners'] is Map
            ? Map<String, dynamic>.from(row['partners'] as Map)
            : const <String, dynamic>{};
        final items = ((row['sales_order_items'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row['order_code'] as String? ?? 'Sales order',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                partner['name'] as String? ?? 'No partner',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${row['status'] ?? 'draft'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...items.map((item) {
                final inventory = item['inventory_items'] is Map
                    ? Map<String, dynamic>.from(item['inventory_items'] as Map)
                    : const <String, dynamic>{};
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(inventory['name'] as String? ?? 'Item'),
                  subtitle: Text('${item['quantity']} × ${item['unit_price']}'),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  int _countFor(String value) {
    if (value == 'all') {
      return _orders.length;
    }
    return _orders.where((o) => _statusOf(o) == value).length;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _applyFilter(_orders);
    return ReferencePageScaffold(
      title: 'Sales',
      onMenuPressed: widget.onMenuPressed,
      showBottomNavigation: false,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateOrder,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _searchController,
            label: 'Search sales',
            hintText: 'Search by order or customer',
            prefixIcon: Icons.search_rounded,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),
          FilterChips(
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
            options: [
              FilterChipOption('all', 'All', count: _countFor('all')),
              FilterChipOption('draft', 'Draft', count: _countFor('draft')),
              FilterChipOption('confirmed', 'Confirmed', count: _countFor('confirmed')),
              FilterChipOption('partial', 'Partial', count: _countFor('partial')),
              FilterChipOption('overdue', 'Overdue', count: _countFor('overdue')),
              FilterChipOption('cancelled', 'Cancelled', count: _countFor('cancelled')),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(itemCount: 5)
          else if (visible.isEmpty)
            const _SalesEmptyState()
          else
            AppSurfaceCard(
              child: Column(
                children: () {
                  final rows = <Widget>[];
                  for (var i = 0; i < visible.length; i++) {
                    final order = visible[i];
                    final partner = order['partners'] is Map
                        ? Map<String, dynamic>.from(order['partners'] as Map)
                        : const <String, dynamic>{};
                    rows.add(
                      _StaggeredListItem(
                        index: i,
                        child: OrderRow(
                          orderCode: order['order_code'] as String? ?? 'Sales order',
                          partnerName: partner['name'] as String? ?? 'No customer',
                          date: DateTime.tryParse((order['order_date'] as String?) ?? '') ?? DateTime.now(),
                          amount: (order['total_amount'] as num?)?.toDouble() ?? 0,
                          status: order['status'] as String? ?? 'draft',
                          type: OrderRowType.sales,
                          onTap: () => _showDetails(order),
                        ),
                      ),
                    );
                    if (i < visible.length - 1) {
                      rows.add(
                        const Divider(height: 1, color: AppColors.line, thickness: 0.8),
                      );
                    }
                  }
                  return rows;
                }(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Consistent empty state for the sales list.
class _SalesEmptyState extends StatelessWidget {
  const _SalesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.warmGray),
          const SizedBox(height: 12),
          Text(
            'No sales yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recorded sales will appear here.',
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
