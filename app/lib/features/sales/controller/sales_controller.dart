import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/features/sales/models/customer_model.dart';
import 'package:liquid_soap_tracker/features/sales/models/sales_dispatch_model.dart';

final salesDispatchesProvider = FutureProvider<List<SalesDispatchModel>>((
  ref,
) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    throw StateError('No signed-in user found.');
  }

  return ref
      .watch(salesRepositoryProvider)
      .fetchRecentDispatches(owner: profile.isOwner, limit: 20);
});

final salesCustomersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  return ref.watch(salesRepositoryProvider).fetchCustomers();
});
