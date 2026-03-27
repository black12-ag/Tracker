import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/bootstrap/app_bootstrap.dart';
import 'package:liquid_soap_tracker/app/bootstrap/app_sync_bootstrap.dart';
import 'package:liquid_soap_tracker/app/theme/app_theme.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/features/splash/page/animated_splash_screen.dart';

class LiquidSoapTrackerApp extends StatelessWidget {
  const LiquidSoapTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppIdentity.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AnimatedSplashScreen(
        child: AppSyncBootstrap(child: AppBootstrap()),
      ),
    );
  }
}
