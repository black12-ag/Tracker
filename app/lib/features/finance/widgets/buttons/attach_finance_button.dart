import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class AttachFinanceButton extends StatelessWidget {
  const AttachFinanceButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Add Money To Sale',
      icon: Icons.link_outlined,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
