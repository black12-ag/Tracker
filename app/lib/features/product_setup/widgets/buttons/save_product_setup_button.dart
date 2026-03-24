import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class SaveProductSetupButton extends StatelessWidget {
  const SaveProductSetupButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Save Product',
      icon: Icons.check_circle_outline,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
