import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';

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
  List<Map<String, dynamic>> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final orders = await ref.read(trackerRepositoryProvider).listPendingShipments();
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

  Future<void> _ship(String orderId) async {
    try {
      await ref.read(trackerRepositoryProvider).shipSalesOrder(orderId);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Shipment',
      onMenuPressed: widget.onMenuPressed,
      child: _isLoading
          ? const ReferenceListPageSkeleton(
              showSearch: false,
              itemCount: 4,
            )
          : _orders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(
                    'No sales orders waiting for shipment.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : AppSurfaceCard(
                  child: Column(
                    children: _orders.map((order) {
                      final partner = order['partners'] is Map
                          ? Map<String, dynamic>.from(order['partners'] as Map)
                          : const <String, dynamic>{};
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(order['order_code'] as String? ?? 'SO'),
                        subtitle: Text(
                          '${partner['name'] ?? 'No customer'} • ${AppFormatters.date(DateTime.tryParse((order['order_date'] as String?) ?? '') ?? DateTime.now())}',
                        ),
                        trailing: SizedBox(
                          width: 110,
                          child: PrimaryButton(
                            label: 'Ship',
                            onPressed: () => _ship(order['id'] as String),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
