import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/features/product_setup/models/product_setup_bundle.dart';

final productSetupBundleProvider = FutureProvider<ProductSetupBundle>((
  ref,
) async {
  final profile = await ref.watch(currentProfileProvider.future);
  if (profile == null) {
    throw StateError('No signed-in user found.');
  }

  return ref
      .watch(productRepositoryProvider)
      .fetchBundle(owner: profile.isOwner);
});
