import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_soap_tracker/app/theme/app_theme.dart';
import 'package:liquid_soap_tracker/core/config/app_identity.dart';
import 'package:liquid_soap_tracker/features/auth/page/login_page.dart';
import 'package:liquid_soap_tracker/features/splash/page/animated_splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        title: AppIdentity.appName,
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  testWidgets('login page renders tracker sign in fields', (tester) async {
    await tester.pumpWidget(wrapApp(const LoginPage()));
    await tester.pump();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('animated splash reveals the child after the intro finishes', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapApp(
        const AnimatedSplashScreen(
          child: Scaffold(body: Center(child: Text('App Ready'))),
        ),
      ),
    );

    expect(find.text('App Ready'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();

    expect(find.text('App Ready'), findsOneWidget);
  });
}
