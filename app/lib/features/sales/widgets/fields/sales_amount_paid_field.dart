import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/fields/app_text_field.dart';

class SalesAmountPaidField extends StatelessWidget {
  const SalesAmountPaidField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Amount paid now',
      hintText: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixIcon: Icons.account_balance_wallet_outlined,
    );
  }
}
