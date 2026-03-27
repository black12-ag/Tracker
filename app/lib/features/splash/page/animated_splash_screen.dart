import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({required this.child, super.key});

  final Widget child;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _fadeTimer;
  Timer? _removeTimer;
  bool _fadeOut = false;
  bool _removeSplash = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..forward();
    _fadeTimer = Timer(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      setState(() => _fadeOut = true);
    });
    _removeTimer = Timer(const Duration(milliseconds: 1380), () {
      if (!mounted) return;
      setState(() => _removeSplash = true);
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _removeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_removeSplash)
          AnimatedOpacity(
            opacity: _fadeOut ? 0 : 1,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: IgnorePointer(
              child: Scaffold(
                body: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final raw = _controller.value;
                    final entrance = Curves.easeOutCubic.transform(
                      raw < 0.68 ? raw / 0.68 : 1,
                    );
                    final settle = raw < 0.64
                        ? 0.0
                        : Curves.easeInOut.transform((raw - 0.64) / 0.36);
                    final logoScale = 0.42 + (entrance * 0.76) - (settle * 0.05);
                    final ringScale = 0.55 + (entrance * 0.68);
                    final tilt = (1 - entrance) * 0.34;
                    final pulse = 1 + (math.sin(raw * math.pi * 2) * 0.014);
                    final backgroundShift = Curves.easeInOut.transform(raw.clamp(0.0, 1.0));

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(const Color(0xFF081A3A), const Color(0xFF123D79), backgroundShift)!,
                            Color.lerp(const Color(0xFF0F2A5F), const Color(0xFF2E79F6), backgroundShift)!,
                            Color.lerp(const Color(0xFF17356A), const Color(0xFF8DBFFF), backgroundShift)!,
                          ],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _SplashOrb(
                            alignment: Alignment.topLeft,
                            size: 220,
                            color: const Color(0xFF9AC7FF).withValues(alpha: 0.18),
                            offsetX: -45 + (backgroundShift * 20),
                            offsetY: -30,
                          ),
                          _SplashOrb(
                            alignment: Alignment.bottomRight,
                            size: 260,
                            color: const Color(0xFF66D6A6).withValues(alpha: 0.14),
                            offsetX: 34,
                            offsetY: 28 - (backgroundShift * 24),
                          ),
                          _SplashOrb(
                            alignment: Alignment.centerRight,
                            size: 160,
                            color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                            offsetX: 92,
                            offsetY: -140,
                          ),
                          Center(
                            child: Transform.scale(
                              scale: pulse,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: raw * math.pi * 1.9,
                                    child: Transform.scale(
                                      scale: ringScale,
                                      child: Container(
                                        width: 250,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.24),
                                            width: 2.8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF8CB9FF).withValues(alpha: 0.18),
                                              blurRadius: 42,
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: -raw * math.pi * 1.2,
                                    child: Transform.scale(
                                      scale: ringScale * 0.78,
                                      child: Container(
                                        width: 250,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF66D6A6).withValues(alpha: 0.28),
                                            width: 5.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0017)
                                      ..rotateY(tilt)
                                      ..rotateX(tilt * 0.18),
                                    child: Transform.scale(
                                      scale: logoScale,
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(42),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/app_icon.png'),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.22),
                                              blurRadius: 34,
                                              spreadRadius: 3,
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF0E2756).withValues(alpha: 0.28),
                                              blurRadius: 24,
                                              offset: const Offset(0, 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashOrb extends StatelessWidget {
  const _SplashOrb({
    required this.alignment,
    required this.size,
    required this.color,
    required this.offsetX,
    required this.offsetY,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double offsetX;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
