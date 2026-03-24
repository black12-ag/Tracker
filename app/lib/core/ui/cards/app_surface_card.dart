import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class AppSurfaceCard extends StatelessWidget {
  const AppSurfaceCard({
    required this.child,
    super.key,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.olive.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
