import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/app/theme/app_motion.dart';

/// The app's primary call-to-action. Solid navy (no gradient, per DESIGN.md),
/// with two layers of motion:
///   1. tactile press-scale + spring release on every tap, and
///   2. a slow, barely-there "breathing" shadow while idle and enabled — the
///      premium live feel, calm enough for a finance tool.
/// Both layers honour reduced-motion (idle breathing stops; press snaps).
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
    with TickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  late final Animation<double> _pressShadow;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: AppMotion.pressIn,
      reverseDuration: AppMotion.pressOut,
    );
    _scale = Tween<double>(begin: 1.0, end: AppMotion.pressScale).animate(
      CurvedAnimation(parent: _press, curve: AppMotion.pressInCurve),
    );
    _pressShadow = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _press, curve: AppMotion.pressInCurve),
    );
    _breath = AnimationController(
      vsync: this,
      duration: AppMotion.ctaBreath,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreathing();
  }

  @override
  void didUpdateWidget(covariant PrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreathing();
  }

  void _syncBreathing() {
    final shouldBreathe = _isActive && !AppMotion.noAnimations(context);
    if (shouldBreathe && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!shouldBreathe && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _breath.dispose();
    super.dispose();
  }

  bool get _isActive => widget.onPressed != null && !widget.isBusy;

  void _down(TapDownDetails _) {
    if (_isActive) _press.forward();
  }

  void _up(TapUpDetails _) {
    _press.reverse();
    if (_isActive) widget.onPressed!();
  }

  void _cancel() => _press.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_press, _breath]),
      builder: (context, child) {
        // Idle breathing modulates shadow softness/lift; multiplied by the
        // press-shadow factor so the glow recedes as the button is pressed.
        final breath = _isActive ? _breath.value : 0.0;
        final shadowFactor = _pressShadow.value;
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
                color: _isActive ? AppColors.navy : AppColors.line,
                borderRadius: BorderRadius.circular(28),
                boxShadow: _isActive
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withValues(
                            alpha: (0.18 + 0.12 * breath) * shadowFactor,
                          ),
                          blurRadius: 16 + 10 * breath,
                          offset: Offset(0, (6 + 3 * breath) * shadowFactor),
                        ),
                      ]
                    : null,
              ),
              child: Center(child: _content(context)),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    if (widget.isBusy) {
      return const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    }
    final fg = _isActive ? Colors.white : AppColors.warmGray;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: 10),
        ],
        Text(
          widget.label,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: fg, letterSpacing: 0.4),
        ),
      ],
    );
  }
}
