import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
    this.label = 'Login',
    this.icon = Icons.arrow_forward,
  });

  final VoidCallback onPressed;
  final bool isBusy;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
