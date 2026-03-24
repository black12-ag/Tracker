import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class SaveProductionButton extends StatelessWidget {
  const SaveProductionButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Add Production',
      icon: Icons.science_outlined,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
