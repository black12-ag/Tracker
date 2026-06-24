import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/features/production/models/production_entry_model.dart';

final productionEntriesProvider = FutureProvider<List<ProductionEntryModel>>((
  ref,
) async {
  return ref.watch(productionRepositoryProvider).fetchRecentEntries(limit: 12);
});
