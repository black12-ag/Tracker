import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    super.key,
    this.subtitle,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.olive;
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: AppColors.olive.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: color),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.warmGray),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(button: true, child: card);
  }
}
