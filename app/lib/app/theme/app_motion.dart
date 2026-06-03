import 'package:flutter/widgets.dart';

/// Centralised motion vocabulary so every animation in the app shares one
/// rhythm and feel. Durations/curves live here only — never hard-code them
/// in widgets. All motion must degrade gracefully when the user has asked
/// for reduced motion (see [AppMotion.noAnimations]).
class AppMotion {
  AppMotion._();

  // --- Press / tap feedback -------------------------------------------------
  /// Press-down: quick so the surface reacts within ~80ms of touch.
  static const Duration pressIn = Duration(milliseconds: 90);

  /// Release: longer, spring-like settle for a tactile feel.
  static const Duration pressOut = Duration(milliseconds: 240);

  /// Scale applied while a tappable surface is pressed.
  static const double pressScale = 0.96;

  /// Slightly gentler press-scale for large surfaces (rows, cards).
  static const double pressScaleSubtle = 0.98;

  static const Curve pressInCurve = Curves.easeOut;
  static const Curve pressOutCurve = Curves.easeOutBack;

  // --- State / content transitions -----------------------------------------
  /// Crossfade between skeleton and loaded content.
  static const Duration stateCrossfade = Duration(milliseconds: 240);

  /// Standard micro-interaction (focus ring, color, expand/collapse).
  static const Duration micro = Duration(milliseconds: 200);

  /// Page / shared-axis route transition.
  static const Duration page = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  // --- List entrance --------------------------------------------------------
  /// Per-item delay for staggered list entrance.
  static const Duration listStaggerStep = Duration(milliseconds: 40);
  static const Duration listItemFade = Duration(milliseconds: 280);

  // --- Financial number roll-up ---------------------------------------------
  static const Duration countUp = Duration(milliseconds: 600);
  static const Curve countUpCurve = Curves.easeOutCubic;

  // --- Primary CTA "breathing" shadow ---------------------------------------
  static const Duration ctaBreath = Duration(milliseconds: 2600);

  /// True when the platform/user requests reduced motion. Widgets should skip
  /// idle/decorative animation and snap state changes when this is set.
  static bool noAnimations(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Returns [normal] unless reduced motion is on, in which case [Duration.zero].
  static Duration respect(BuildContext context, Duration normal) =>
      noAnimations(context) ? Duration.zero : normal;
}
