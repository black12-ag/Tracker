import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/core/providers/core_providers.dart';
import 'package:tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:tracker/core/ui/states/app_error_view.dart';
import 'package:tracker/core/ui/states/app_loading_view.dart';
import 'package:tracker/features/admin_logs/controller/admin_logs_controller.dart';
import 'package:tracker/features/admin_logs/models/activity_log_entry.dart';

class AdminLogsPage extends ConsumerStatefulWidget {
  const AdminLogsPage({required this.onMenuPressed, super.key});
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends ConsumerState<AdminLogsPage> {
  final _scrollController = ScrollController();
  String _selectedFilter = 'All';

  static const _filters = {
    'All': null,
    'Auth': 'auth',
    'Sales': 'sales',
    'Finance': 'finance',
    'Staff': 'staff',
    'Inventory': 'inventory',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(adminLogsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile?.isOwner != true) {
      return ReferencePageScaffold(
        title: 'Activity Logs',
        onMenuPressed: widget.onMenuPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'This section is for the owner only.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final state = ref.watch(adminLogsControllerProvider);

    return ReferencePageScaffold(
      title: 'Admin Logs',
      onMenuPressed: widget.onMenuPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((entry) {
                final isSelected = _selectedFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    selectedColor: AppColors.navy.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.navy,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.navy : AppColors.warmGray,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilter = entry.key);
                      ref.read(adminLogsControllerProvider.notifier)
                          .load(eventTypeFilter: entry.value);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          if (state.isLoading)
            const AppLoadingView()
          else if (state.errorMessage != null)
            AppErrorView(
              title: 'Could not load logs',
              message: state.errorMessage!,
              actionLabel: 'Retry',
              onPressed: () =>
                  ref.read(adminLogsControllerProvider.notifier).load(),
            )
          else if (state.logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Center(
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
                        child: const Icon(Icons.history_outlined,
                            size: 26, color: AppColors.navy),
                      ),
                      const SizedBox(height: 14),
                      Text('No activity yet',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        'Actions across the app will show up here as they happen.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.warmGray),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  state.logs.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.line, thickness: 0.8),
              itemBuilder: (context, index) {
                if (index == state.logs.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  );
                }
                return _LogTile(log: state.logs[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final ActivityLogEntry log;

  IconData _icon() {
    final e = log.eventType;
    if (e.startsWith('auth')) return Icons.lock_outline;
    if (e.startsWith('finance')) return Icons.account_balance_outlined;
    if (e.startsWith('staff')) return Icons.badge_outlined;
    if (e.startsWith('sales')) return Icons.shopping_cart_outlined;
    if (e.startsWith('inventory')) return Icons.inventory_2_outlined;
    return Icons.info_outline;
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_icon(), color: AppColors.navy, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.charcoal, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${log.actorName}  •  ${log.eventType}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warmGray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDate(log.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warmGray),
          ),
        ],
      ),
    );
  }
}
