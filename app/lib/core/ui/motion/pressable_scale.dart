import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_motion.dart';

/// Wraps any widget with the app's unified press-scale feedback: a quick
/// scale-down on touch and a spring-back release. This is the single source
/// of "tactile" feel — buttons, rows and tappable cards all use it so the
/// whole app reacts the same way. Honours reduced-motion (snaps, no scale).
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    required this.onTap,
    super.key,
    this.scale = AppMotion.pressScale,
    this.enabled = true,
    this.semanticButton = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool enabled;
  final bool semanticButton;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.pressIn,
      reverseDuration: AppMotion.pressOut,
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.pressInCurve),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _active => widget.enabled && widget.onTap != null;

  void _down(TapDownDetails _) {
    if (_active && !AppMotion.noAnimations(context)) _ctrl.forward();
  }

  void _up(TapUpDetails _) {
    _ctrl.reverse();
    if (_active) widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.semanticButton,
      enabled: _active,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
