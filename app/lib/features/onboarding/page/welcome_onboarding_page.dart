import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

/// One-time welcome shown the first time a freshly registered owner opens
/// the app. Sets expectations for a brand-new, empty workspace so the user
/// is not dropped into a blank dashboard with no guidance.
class WelcomeOnboardingPage extends StatelessWidget {
  const WelcomeOnboardingPage({
    required this.profile,
    required this.onContinue,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final firstName = profile.displayName.trim().split(' ').first;
    final greeting = firstName.isNotEmpty ? 'Welcome, $firstName' : 'Welcome';

    const steps = <_OnboardStep>[
      _OnboardStep(
        icon: Icons.inventory_2_outlined,
        title: 'Add your products',
        body: 'Set up the items you sell, with prices and stock.',
      ),
      _OnboardStep(
        icon: Icons.point_of_sale_outlined,
        title: 'Record sales & purchases',
        body: 'Log money in and out as it happens — even offline.',
      ),
      _OnboardStep(
        icon: Icons.groups_outlined,
        title: 'Invite your staff',
        body: 'Create staff accounts so your team can record work.',
      ),
      _OnboardStep(
        icon: Icons.insights_outlined,
        title: 'See profit at a glance',
        body: 'Revenue, balances owed, and profit are always ready.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                greeting,
                style: textTheme.displayLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Your workspace is ready. Here is how Tracker keeps your '
                'daily numbers in one place.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.warmGray),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView.separated(
                  itemCount: steps.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) => steps[index],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Get started',
                icon: Icons.arrow_forward,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardStep extends StatelessWidget {
  const _OnboardStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.navy, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.warmGray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
