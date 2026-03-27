import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';
import 'package:liquid_soap_tracker/features/purchased/page/purchase_order_page.dart';

class PurchasedPage extends ConsumerStatefulWidget {
  const PurchasedPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<PurchasedPage> createState() => _PurchasedPageState();
}

class _PurchasedPageState extends ConsumerState<PurchasedPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = const [];

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
      final orders = await ref.read(trackerRepositoryProvider).listPurchaseOrders(
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
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCreateOrder() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PurchaseOrderPage(profile: widget.profile),
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
        final items = ((row['purchase_order_items'] as List?) ?? const [])
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
                row['order_code'] as String? ?? 'Purchase order',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                partner['name'] as String? ?? 'No supplier',
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

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Purchased',
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
            label: 'Search purchased',
            hintText: 'Search by order or supplier',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => _load(),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(itemCount: 5)
          else if (_orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Text(
                'No purchase orders found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            AppSurfaceCard(
              child: Column(
                children: _orders.map((order) {
                  final partner = order['partners'] is Map
                      ? Map<String, dynamic>.from(order['partners'] as Map)
                      : const <String, dynamic>{};
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _showDetails(order),
                    title: Text(
                      order['order_code'] as String? ?? 'Purchase order',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${partner['name'] ?? 'No supplier'} • ${AppFormatters.date(DateTime.tryParse((order['order_date'] as String?) ?? '') ?? DateTime.now())}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.currency(
                            (order['total_amount'] as num?)?.toDouble() ?? 0,
                          ),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.navy,
                              ),
                        ),
                        Text(
                          order['status'] as String? ?? 'draft',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
