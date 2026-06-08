import 'package:flutter/material.dart';
import '../../../widgets/glass_button.dart';

class AcknowledgeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AcknowledgeButton({
    super.key,
    required this.onPressed,
    this.label = 'Done',
  });

  @override
  Widget build(BuildContext context) {
    return GlassPrimaryButton(
      label: label,
      onPressed: onPressed,
      width: double.infinity,
      height: 56,
    );
  }
}
