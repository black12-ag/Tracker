import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/secondary_button.dart';
import 'package:liquid_soap_tracker/core/ui/layout/app_page_scaffold.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      subtitle: message,
      child: SecondaryButton(label: actionLabel, onPressed: onPressed),
    );
  }
}
