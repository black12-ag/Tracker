import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/ghost_button.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/utils/app_errors.dart';
import 'package:liquid_soap_tracker/features/profile/page/profile_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final password = _passwordController.text.trim();
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters long.'),
        ),
      );
      return;
    }
    if (password != _confirmController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(password);
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.humanize(error))));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(selectedShellTabProvider.notifier).state = 0;
    ref.invalidate(currentProfileProvider);
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 0.8,
          fontSize: 11,
          color: AppColors.warmGray,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Settings',
      onMenuPressed: widget.onMenuPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: YOUR PROFILE ────────────────────────────────
          _sectionLabel(context, 'YOUR PROFILE'),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: AppColors.navy,
                      child: Text(
                        (widget.profile.displayName.isNotEmpty
                                ? widget.profile.displayName[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profile.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            widget.profile.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.warmGray),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.profile.isOwner
                                  ? AppColors.navy
                                  : AppColors.accentBlueDark,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.profile.isOwner ? 'Owner' : 'Staff',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GhostButton(
                  label: 'Edit Profile',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ProfilePage(
                        profile: widget.profile,
                        onMenuPressed: widget.onMenuPressed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Section 2: SECURITY ────────────────────────────────────
          _sectionLabel(context, 'SECURITY'),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _passwordController,
                  label: 'New password',
                  hintText: 'Enter new password',
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  hintText: 'Repeat new password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Update Password',
                  isBusy: _isSaving,
                  onPressed: _changePassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Section 3: ACCOUNT ─────────────────────────────────────
          _sectionLabel(context, 'ACCOUNT'),
          AppSurfaceCard(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
                child: const Text('Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
