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

class ReceivePage extends ConsumerStatefulWidget {
  const ReceivePage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends ConsumerState<ReceivePage> {
  bool _isLoading = true;
  final Set<String> _receiving = {};
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
          await ref.read(trackerRepositoryProvider).listPendingReceives();
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

  Future<void> _confirmAndReceive(
    String orderId,
    String orderCode,
    String supplierName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as received?'),
        content: Text(
          'Order $orderCode from $supplierName will be marked as received. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Receive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _receive(orderId);
  }

  Future<void> _receive(String orderId) async {
    if (_receiving.contains(orderId)) return;
    setState(() => _receiving.add(orderId));
    try {
      await ref.read(trackerRepositoryProvider).receivePurchaseOrder(orderId);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppErrors.humanize(error))),
      );
    } finally {
      if (mounted) setState(() => _receiving.remove(orderId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Receive',
      onMenuPressed: widget.onMenuPressed,
      child: _isLoading
          ? const ReferenceListPageSkeleton(showSearch: false, itemCount: 4)
          : _orders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: _EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nothing to receive',
                    message:
                        'Create a purchase order first, then come back here to receive it.',
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
                      final orderCode = order['order_code'] as String? ?? 'PO';
                      final supplierName =
                          partner['name'] as String? ?? 'No supplier';
                      final isBusy = _receiving.contains(orderId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(orderCode),
                        subtitle: Text(
                          '$supplierName • ${AppFormatters.date(DateTime.tryParse((order['order_date'] as String?) ?? '') ?? DateTime.now())}',
                        ),
                        trailing: SizedBox(
                          width: 110,
                          child: PrimaryButton(
                            label: 'Receive',
                            isBusy: isBusy,
                            onPressed: isBusy
                                ? null
                                : () => _confirmAndReceive(
                                      orderId,
                                      orderCode,
                                      supplierName,
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
