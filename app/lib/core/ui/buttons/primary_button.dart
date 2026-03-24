import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBusy ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 10),
          ],
          Text(label),
        ],
      ),
    );
  }
}
