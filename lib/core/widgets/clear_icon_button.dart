import 'package:flutter/material.dart';

class ClearIconButton extends StatelessWidget {
  const ClearIconButton({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return controller.text.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Light gray background
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: controller.clear,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
