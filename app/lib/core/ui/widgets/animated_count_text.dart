import 'package:flutter/material.dart';
import 'package:tracker/app/theme/app_motion.dart';

/// Rolls a numeric value up to its target on first build and whenever the
/// value changes — the premium "numbers are the product" feel on dashboard,
/// finance and reports. Pass a [formatter] (e.g. AppFormatters.currency) so
/// the interpolated double is rendered correctly each frame.
///
/// Honours reduced-motion: when disabled, the final value is shown instantly.
class AnimatedCountText extends StatelessWidget {
  const AnimatedCountText({
    required this.value,
    required this.formatter,
    super.key,
    this.style,
    this.duration,
    this.textAlign,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration? duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final d = AppMotion.respect(context, duration ?? AppMotion.countUp);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: d,
      curve: AppMotion.countUpCurve,
      builder: (context, animated, _) => Text(
        formatter(animated),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
