import 'package:flutter/material.dart';

class ClearIconButton extends StatelessWidget {
  const ClearIconButton({
    super.key,
    required this.controller,
    this.otherControllers,
  });

  final TextEditingController controller; 
  final List<TextEditingController>? otherControllers;

  @override
  Widget build(BuildContext context) {
    return controller.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
            controller.clear();
            if (otherControllers != null) {
              for (final TextEditingController otherController in otherControllers!) {
                otherController.clear();
              }
            }
          },
          )
        : const SizedBox.shrink();
  }
}
