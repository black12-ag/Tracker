import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({required this.child, super.key});

  final Widget child;

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  bool _showChild = false;
  bool _initializing = true;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoState);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenVideo = prefs.getBool(AppIdentity.splashSeenKey) ?? false;

    if (hasSeenVideo) {
      if (!mounted) {
        return;
      }
      setState(() {
        _showChild = true;
        _initializing = false;
      });
      return;
    }

    final controller = VideoPlayerController.asset(
      'assets/videos/splash_video.mp4',
    );

    try {
      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(_handleVideoState);
      await controller.play();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      await prefs.setBool(AppIdentity.splashSeenKey, true);
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.dispose();
      setState(() {
        _showChild = true;
        _initializing = false;
      });
    }
  }

  Future<void> _completeSplash() async {
    if (_hasCompleted) {
      return;
    }
    _hasCompleted = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppIdentity.splashSeenKey, true);

    _controller?.pause();
    _controller?.removeListener(_handleVideoState);

    if (!mounted) {
      return;
    }

    setState(() {
      _showChild = true;
    });
  }

  void _handleVideoState() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration > Duration.zero && position >= duration) {
      _completeSplash();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) {
      return widget.child;
    }

    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF0F2A5F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: const Color(0xFF0F2A5F),
            child: _initializing || controller == null || !controller.value.isInitialized
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: TextButton(
              onPressed: _completeSplash,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.28),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
          if (_initializing)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Text(
                  AppIdentity.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
