import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/app/theme/app_colors.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppIdentity.appName.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 3,
                  color: AppColors.oliveDark,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppIdentity.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Preparing your workspace...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.oliveDark),
            ],
          ),
        ),
      ),
    );
  }
}
