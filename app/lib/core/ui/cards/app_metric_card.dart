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
    final accent = accentColor ?? AppColors.mint;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              letterSpacing: 0.6,
                              fontSize: 10,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warmGray,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return Semantics(button: true, child: card);
  }
}
