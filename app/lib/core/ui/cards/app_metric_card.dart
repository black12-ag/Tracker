import 'package:flutter/material.dart';
import 'package:tracker/app/theme/app_colors.dart';
import 'package:tracker/core/ui/widgets/animated_count_text.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    required this.label,
    required this.value,
    super.key,
    this.subtitle,
    this.accentColor,
    this.onTap,
    this.animatedValue,
    this.valueFormatter,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;

  /// When provided (with [valueFormatter]), the value rolls up from 0 to this
  /// number on load instead of showing [value] statically.
  final double? animatedValue;
  final String Function(double)? valueFormatter;

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
                Builder(
                  builder: (context) {
                    final valueStyle = Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        );
                    if (animatedValue != null && valueFormatter != null) {
                      return AnimatedCountText(
                        value: animatedValue!,
                        formatter: valueFormatter!,
                        style: valueStyle,
                      );
                    }
                    return Text(value, style: valueStyle);
                  },
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
