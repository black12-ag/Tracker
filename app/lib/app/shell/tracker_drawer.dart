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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                children: [
                  if (profile.isOwner) ...[
                    _DrawerTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Loan Records',
                      onTap: onOpenLoanRecords,
                    ),
                    _DrawerTile(
                      icon: Icons.receipt_long_outlined,
                      label: 'Expenses',
                      onTap: onOpenExpenses,
                    ),
                    _DrawerTile(
                      icon: Icons.tune_rounded,
                      label: 'Inventory Adjustment',
                      onTap: onOpenInventoryAdjustment,
                    ),
                  ],
                  _DrawerTile(
                    icon: Icons.move_to_inbox_outlined,
                    label: 'Receive',
                    onTap: onOpenReceive,
                  ),
                  _DrawerTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Shipment',
                    onTap: onOpenShipment,
                  ),
                  _DrawerTile(
                    icon: Icons.people_outline_rounded,
                    label: 'Partners',
                    onTap: onOpenPartners,
                  ),
                  if (profile.isOwner)
                    _DrawerTile(
                      icon: Icons.badge_outlined,
                      label: 'Employees',
                      onTap: onOpenEmployees,
                    ),
                  if (profile.isOwner)
                    _DrawerTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      onTap: onOpenReports,
                    ),
                ],
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
