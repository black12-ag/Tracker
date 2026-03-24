import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/secondary_button.dart';

class SaveExpenseButton extends StatelessWidget {
  const SaveExpenseButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: isBusy ? 'Saving expense...' : 'Save Expense',
      icon: Icons.receipt_long_outlined,
      onPressed: isBusy ? null : onPressed,
    );
  }
}
