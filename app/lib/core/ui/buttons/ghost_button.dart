import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class GhostButton extends StatefulWidget {
  const GhostButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _fill = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isActive => widget.onPressed != null;

  void _down(TapDownDetails _) {
    if (_isActive) _ctrl.forward();
  }

  void _up(TapUpDetails _) {
    _ctrl.reverse();
    if (_isActive) widget.onPressed!();
  }

  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: GestureDetector(
            onTapDown: _down,
            onTapUp: _up,
            onTapCancel: _cancel,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06 * _fill.value),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.navy
                      .withValues(alpha: 0.18 + 0.22 * _fill.value),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: _isActive
                            ? AppColors.navy
                            : AppColors.warmGray,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _isActive
                                ? AppColors.navy
                                : AppColors.warmGray,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
