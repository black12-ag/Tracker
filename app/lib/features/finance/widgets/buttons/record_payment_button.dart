import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/primary_button.dart';

class RecordPaymentButton extends StatelessWidget {
  const RecordPaymentButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: 'Add Payment',
      icon: Icons.payments_outlined,
      onPressed: onPressed,
      isBusy: isBusy,
    );
  }
}
