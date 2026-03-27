import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/models/app_profile.dart';
import 'package:liquid_soap_tracker/core/providers/core_providers.dart';
import 'package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';
import 'package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart';
import 'package:liquid_soap_tracker/core/ui/states/reference_page_skeleton.dart';
import 'package:liquid_soap_tracker/features/partners/widgets/partner_form_dialog.dart';

class PartnersPage extends ConsumerStatefulWidget {
  const PartnersPage({
    required this.profile,
    required this.onMenuPressed,
    super.key,
  });

  final AppProfile profile;
  final VoidCallback onMenuPressed;

  @override
  ConsumerState<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends ConsumerState<PartnersPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _partners = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final partners = await ref.read(trackerRepositoryProvider).listPartners(
            search: _searchController.text,
          );
      if (!mounted) {
        return;
      }
      setState(() => _partners = partners);
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

  Future<void> _addPartner() async {
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => PartnerFormDialog(createdBy: widget.profile.id),
    );
    if (saved != null) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReferencePageScaffold(
      title: 'Partners',
      onMenuPressed: widget.onMenuPressed,
      floatingActionButton: FloatingActionButton(
        onPressed: _addPartner,
        backgroundColor: AppColors.mint,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      child: Column(
        children: [
          AppTextField(
            controller: _searchController,
            label: 'Search partners',
            hintText: 'Search by name or phone',
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => _load(),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const ReferenceListPageSkeleton(itemCount: 5)
          else if (_partners.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Text(
                'No partners found.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            AppSurfaceCard(
              child: Column(
                children: _partners.map((partner) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      partner['name'] as String? ?? 'Partner',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      [
                        partner['phone'] as String? ?? '',
                        partner['partner_type'] as String? ?? '',
                      ].where((value) => value.isNotEmpty).join(' • '),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
