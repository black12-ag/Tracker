import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/core/models/app_profile.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/core/ui/buttons/primary_button.dart';
import 'package:tracker/core/ui/cards/app_surface_card.dart';
import 'package:tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:tracker/core/utils/app_errors.dart';
import 'package:tracker/core/utils/formatters.dart';

class ShipmentPage extends ConsumerStatefulWidget {
  const ShipmentPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<ShipmentPage> createState() => _ShipmentPageState();
}

class _ShipmentPageState extends ConsumerState<ShipmentPage> {
  bool _isLoading = true;
  final Set<String> _shipping = {};
  List<Map<String, dynamic>> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders =
          await ref.read(trackerRepositoryProvider).listPendingShipments();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.humanize(error))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndShip(
    String orderId,
    String orderCode,
    String customerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as shipped?'),
        content: Text(
          'Order $orderCode for $customerName will be marked as shipped. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ship'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _ship(orderId);
  }

  Future<void> _ship(String orderId) async {
    if (_shipping.contains(orderId)) return;
    setState(() => _shipping.add(orderId));
    try {
      await ref.read(trackerRepositoryProvider).shipSalesOrder(orderId);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.humanize(error))),
      );
    } finally {
      if (mounted) setState(() => _shipping.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Shipment',
      onMenuPressed: widget.onMenuPressed,
      child: _isLoading
          ? const ReferenceListPageSkeleton(showSearch: false, itemCount: 4)
          : _orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: _EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Nothing to ship',
                    message:
                        'Once a sales order is ready, it will appear here for shipment.',
                  ),
                )
              : AppSurfaceCard(
                  child: Column(
                    children: _orders.map((order) {
                      final partner = order['partners'] is Map
                          ? Map<String, dynamic>.from(
                              order['partners'] as Map)
                          : const <String, dynamic>{};
                      final orderId = order['id'] as String;
                      final orderCode = order['order_code'] as String? ?? 'SO';
                      final customerName =
                          partner['name'] as String? ?? 'No customer';
                      final isBusy = _shipping.contains(orderId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(orderCode),
                        subtitle: Text(
                          '$customerName • ${AppFormatters.date(DateTime.tryParse((order['order_date'] as String?) ?? '') ?? DateTime.now())}',
                        ),
                        trailing: SizedBox(
                          width: 110,
                          child: PrimaryButton(
                            label: 'Ship',
                            isBusy: isBusy,
                            onPressed: isBusy
                                ? null
                                : () => _confirmAndShip(
                                      orderId,
                                      orderCode,
                                      customerName,
                                    ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 26, color: AppColors.navy),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.warmGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
