import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/ui/motion/pressable_scale.dart';

/// Secondary action. Tonal fill, navy text, same height/radius as the primary
/// button, with the shared press-scale feedback (the stock FilledButton gave
/// no tactile response — that read as flat/generic).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final fg = enabled ? AppColors.accentBlueDark : AppColors.warmGray;
    return PressableScale(
      onTap: onPressed,
      enabled: enabled,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.paleGold
              : AppColors.line.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: fg, letterSpacing: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
