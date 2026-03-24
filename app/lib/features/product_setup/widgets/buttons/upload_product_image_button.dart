import 'package:flutter/material.dart';
import 'package:liquid_soap_tracker/core/ui/buttons/secondary_button.dart';

class UploadProductImageButton extends StatelessWidget {
  const UploadProductImageButton({
    required this.onPressed,
    required this.isBusy,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      label: isBusy ? 'Uploading photo...' : 'Add or change photo',
      icon: Icons.add_a_photo_outlined,
      onPressed: isBusy ? null : onPressed,
    );
  }
}
