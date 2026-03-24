import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class SaveProductSizeButton extends StatelessWidget {
  const SaveProductSizeButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Save size',
      icon: Icons.check_circle_outline_rounded,
      onPressed: onPressed,
    );
  }
}
