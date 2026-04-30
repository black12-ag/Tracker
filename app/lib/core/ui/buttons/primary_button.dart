import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _shadow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _shadow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isActive => widget.onPressed != null && !widget.isBusy;

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
                gradient: _isActive
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1D5BA6), AppColors.navy],
                      )
                    : null,
                color: _isActive ? null : AppColors.line,
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isActive
                    ? [
                        BoxShadow(
                          color: AppColors.navy
                              .withValues(alpha: 0.32 * _shadow.value),
                          blurRadius: 20,
                          offset: Offset(0, 7 * _shadow.value),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.isBusy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: 18,
                              color: _isActive
                                  ? Colors.white
                                  : AppColors.warmGray,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: _isActive
                                      ? Colors.white
                                      : AppColors.warmGray,
                                  letterSpacing: 0.4,
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
