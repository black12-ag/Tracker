import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/ui/rows/order_row.dart';

class EmployeeRow extends StatelessWidget {
  const EmployeeRow({
    required this.displayName,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final String displayName;
  final String phone;
  final String email;
  final bool isActive;
  final VoidCallback onTap;

  /// Extracts initials from display name (e.g. "John Doe" -> "JD")
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(displayName);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar circle with initials
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Employee info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    phone.isNotEmpty && email.isNotEmpty
                        ? '$phone  •  $email'
                        : phone.isNotEmpty
                            ? phone
                            : email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.warmGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status badge
            StatusBadge(status: isActive ? 'active' : 'inactive'),
          ],
        ),
      ),
    );
  }
}
