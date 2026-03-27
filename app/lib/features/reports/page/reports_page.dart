import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/formatters.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _reports = const {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ref.read(trackerRepositoryProvider).fetchReports();
      if (!mounted) {
        return;
      }
      setState(() => _reports = reports);
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

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isOwner) {
      return ReferencePageScaffold(
        title: 'Reports',
        onMenuPressed: widget.onMenuPressed,
        child: AppSurfaceCard(
          child: Text(
            'Reports are available only for the owner account.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ReferencePageScaffold(
      title: 'Reports',
      onMenuPressed: widget.onMenuPressed,
      child: _isLoading
          ? const ReferenceReportsSkeleton()
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.navy,
                    labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    unselectedLabelStyle: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    indicator: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    tabs: const [
                      Tab(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Sales'),
                      )),
                      Tab(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Purchased'),
                      )),
                      Tab(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Inventory'),
                      )),
                      Tab(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('Adjustments'),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SummaryTab(
                        data: Map<String, dynamic>.from(
                          (_reports['sales'] as Map?) ?? const {},
                        ),
                      ),
                      _SummaryTab(
                        data: Map<String, dynamic>.from(
                          (_reports['purchased'] as Map?) ?? const {},
                        ),
                      ),
                      _SummaryTab(
                        data: Map<String, dynamic>.from(
                          (_reports['inventory'] as Map?) ?? const {},
                        ),
                      ),
                      _SummaryTab(
                        data: Map<String, dynamic>.from(
                          (_reports['adjustments'] as Map?) ?? const {},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.data});

  final Map<String, dynamic> data;

  String _formatValue(String key, dynamic value) {
    if (value == null) {
      return '-';
    }
    if (value is! num) {
      return '$value';
    }

    final normalizedKey = key.toLowerCase();
    final isPercent = normalizedKey.contains('margin') ||
        normalizedKey.contains('rate');
    final isCurrency = normalizedKey.contains('amount') ||
        normalizedKey.contains('value') ||
        normalizedKey.contains('profit') ||
        normalizedKey.contains('revenue') ||
        normalizedKey.contains('balance') ||
        normalizedKey.contains('bank') ||
        normalizedKey.contains('asset');

    if (isPercent) {
      return '${value.toStringAsFixed(2)}%';
    }
    if (isCurrency) {
      return AppFormatters.currency(value.toDouble());
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AppSurfaceCard(
        child: Text(
          'No data available yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: data.entries.take(8).map((entry) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 56) / 2,
              child: AppSurfaceCard(
                color: AppColors.cream,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatValue(entry.key, entry.value),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.navy,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
