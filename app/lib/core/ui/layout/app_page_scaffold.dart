import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_sync_service.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';

class AppPageScaffold extends ConsumerWidget {
  const AppPageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cream, AppColors.background],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: leading,
                    ),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.warmGray),
                        ),
                      ],
                    ),
                  ),
                  // ignore: use_null_aware_elements
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 24),
              if (!isOnline || pendingSyncCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: !isOnline
                        ? AppColors.warning.withValues(alpha: 0.14)
                        : AppColors.olive.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !isOnline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                        color: !isOnline ? AppColors.warning : AppColors.olive,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          !isOnline
                              ? 'Offline mode is on. Your changes will sync when the internet returns.'
                              : '$pendingSyncCount change${pendingSyncCount == 1 ? '' : 's'} waiting to sync.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
