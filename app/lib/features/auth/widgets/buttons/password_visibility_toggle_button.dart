import 'package:flutter/material.dart';

class PasswordVisibilityToggleButton extends StatelessWidget {
  const PasswordVisibilityToggleButton({
    required this.isVisible,
    required this.onPressed,
    super.key,
  });

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isVisible ? 'Hide password' : 'Show password',
      onPressed: onPressed,
      icon: Icon(
        isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      ),
    );
  }
}
