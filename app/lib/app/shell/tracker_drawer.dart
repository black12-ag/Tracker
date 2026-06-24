import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';

class TrackerDrawer extends StatelessWidget {
  const TrackerDrawer({
    required this.profile,
    required this.onOpenLoanRecords,
    required this.onOpenExpenses,
    required this.onOpenInventoryAdjustment,
    required this.onOpenReceive,
    required this.onOpenShipment,
    required this.onOpenPartners,
    required this.onOpenEmployees,
    required this.onOpenReports,
    required this.onOpenAdminLogs,
    required this.onOpenProfile,
    required this.onOpenSettings,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onOpenLoanRecords;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenInventoryAdjustment;
  final VoidCallback onOpenReceive;
  final VoidCallback onOpenShipment;
  final VoidCallback onOpenPartners;
  final VoidCallback onOpenEmployees;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenAdminLogs;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.mintSoft,
                border: Border(
                  bottom: BorderSide(color: AppColors.line),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracker',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.isOwner ? 'Owner access' : 'Staff access',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.warmGray),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.phone ?? profile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.warmGray,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                children: _buildMenuItems(context),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _FooterButton(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: onOpenProfile,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FooterButton(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: onOpenSettings,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final isOwner = profile.isOwner;
    final sections = <_DrawerSection>[
      _DrawerSection('Money', [
        if (isOwner)
          _DrawerItem(Icons.account_balance_wallet_outlined, 'Loan Records',
              onOpenLoanRecords),
        if (isOwner)
          _DrawerItem(Icons.receipt_long_outlined, 'Expenses', onOpenExpenses),
        if (isOwner)
          _DrawerItem(Icons.bar_chart_rounded, 'Reports', onOpenReports),
      ]),
      _DrawerSection('Operations', [
        _DrawerItem(Icons.move_to_inbox_outlined, 'Receive', onOpenReceive),
        _DrawerItem(Icons.local_shipping_outlined, 'Shipment', onOpenShipment),
        if (isOwner)
          _DrawerItem(Icons.tune_rounded, 'Inventory Adjustment',
              onOpenInventoryAdjustment),
      ]),
      _DrawerSection('People', [
        _DrawerItem(Icons.people_outline_rounded, 'Partners', onOpenPartners),
        if (isOwner)
          _DrawerItem(Icons.badge_outlined, 'Employees', onOpenEmployees),
      ]),
      _DrawerSection('System', [
        if (isOwner)
          _DrawerItem(Icons.admin_panel_settings_outlined, 'Admin Logs',
              onOpenAdminLogs),
      ]),
    ];

    final children = <Widget>[];
    for (final section in sections) {
      if (section.items.isEmpty) {
        continue;
      }
      children.add(_DrawerSectionHeader(label: section.title));
      for (final item in section.items) {
        children.add(
          _DrawerTile(icon: item.icon, label: item.label, onTap: item.onTap),
        );
      }
      children.add(const SizedBox(height: 8));
    }
    return children;
  }
}

class _DrawerSection {
  const _DrawerSection(this.title, this.items);
  final String title;
  final List<_DrawerItem> items;
}

class _DrawerItem {
  const _DrawerItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.warmGray,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: AppColors.navy),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
