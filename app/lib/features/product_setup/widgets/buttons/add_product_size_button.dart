import 'package:flutter/material.dart';

class AddProductSizeButton extends StatelessWidget {
  const AddProductSizeButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
      label: const Text('Add size'),
    );
  }
}
