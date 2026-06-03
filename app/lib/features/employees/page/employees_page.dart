import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/rows/employee_row.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/core/utils/app_errors.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _employees = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final employees = await ref.read(trackerRepositoryProvider).listEmployees();
      if (!mounted) {
        return;
      }
      setState(() => _employees = employees);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrors.humanize(error))));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addEmployee() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => const _AddEmployeeDialog(),
    );
    if (saved == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isOwner) {
      return ReferencePageScaffold(
        title: 'Employees',
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
    return ReferencePageScaffold(
      title: 'Employees',
      onMenuPressed: widget.onMenuPressed,
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: _isLoading
          ? const ReferenceListPageSkeleton(
              showSearch: false,
              itemCount: 5,
            )
          : _employees.isEmpty
              ? const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: _EmptyState(
                    icon: Icons.badge_outlined,
                    title: 'No employees yet',
                    message:
                        'Add a staff member to give them access and track their activity.',
                  ),
                )
              : AppSurfaceCard(
                  child: Column(
                    children: _employees.indexed.map((entry) {
                      final index = entry.$1;
                      final employee = entry.$2;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EmployeeRow(
                            displayName: employee['display_name'] as String? ?? '',
                            phone: employee['phone'] as String? ?? '',
                            email: employee['email'] as String? ?? '',
                            isActive: employee['is_active'] as bool? ?? false,
                            onTap: () {},
                          ),
                          if (index < _employees.length - 1)
                            const Divider(height: 1, color: AppColors.line, thickness: 0.8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}

class _AddEmployeeDialog extends ConsumerStatefulWidget {
  const _AddEmployeeDialog();

  @override
  ConsumerState<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<_AddEmployeeDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  bool _isSaving = false;
  String? _nameError;
  String? _phoneError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nameEmpty = _nameController.text.trim().isEmpty;
    final phoneEmpty = _phoneController.text.trim().isEmpty;
    final passwordEmpty = _passwordController.text.trim().isEmpty;
    if (nameEmpty || phoneEmpty || passwordEmpty) {
      setState(() {
        _nameError = nameEmpty ? 'Name is required' : null;
        _phoneError = phoneEmpty ? 'Phone number is required' : null;
        _passwordError = passwordEmpty ? 'Password is required' : null;
      });
      return;
    }

    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _isSaving = true;
    });
    try {
      await ref.read(trackerRepositoryProvider).createStaff(
            name: _nameController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('New Employee'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hintText: 'Enter name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'Enter phone number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              errorText: _passwordError,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 120,
          child: PrimaryButton(
            label: 'Save',
            isBusy: _isSaving,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              child: Icon(icon, size: 26, color: AppColors.navy),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.warmGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
