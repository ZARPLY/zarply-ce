import 'package:flutter/material.dart';

class ClearIconButton extends StatelessWidget {
  const ClearIconButton({
    super.key,
    required this.controller,
  });

  final TextEditingController controller; 

  @override
  Widget build(BuildContext context) {
    return controller.text.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
            controller.clear();
          },
          )
        : const SizedBox.shrink();
  }
}
