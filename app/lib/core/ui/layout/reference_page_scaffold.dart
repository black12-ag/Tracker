import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/offline/services/offline_sync_service.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/layout/tracker_bottom_navigation.dart';

class ReferencePageScaffold extends ConsumerWidget {
  const ReferencePageScaffold({
    required this.title,
    required this.child,
    super.key,
    this.onMenuPressed,
    this.actions = const [],
    this.floatingActionButton,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
    this.showBottomNavigation = true,
  });

  final String title;
  final Widget child;
  final VoidCallback? onMenuPressed;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final EdgeInsets padding;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNavigation
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: const TrackerBottomNavigation(embedded: true),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: padding,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onMenuPressed,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.navy,
                  ),
                  icon: const Icon(Icons.menu_rounded),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (actions.isEmpty)
                  const SizedBox(width: 48)
                else
                  Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ),
            const SizedBox(height: 18),
            if (!isOnline || pendingSyncCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: !isOnline
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.mintSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      !isOnline ? Icons.wifi_off_rounded : Icons.sync_rounded,
                      color: !isOnline ? AppColors.warning : AppColors.mint,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        !isOnline
                            ? 'Internet is off. Some screens can still open from cache, but new saves may need a connection.'
                            : '$pendingSyncCount change${pendingSyncCount == 1 ? '' : 's'} waiting to sync.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.warmGray,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
