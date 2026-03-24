import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class SaveSaleButton extends StatelessWidget {
  const SaveSaleButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Save Sale',
      icon: Icons.point_of_sale,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
