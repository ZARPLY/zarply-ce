import 'package:flutter/material.dart';

class ClearIconButton extends StatelessWidget {
  const ClearIconButton({
    required this.controller,
    super.key,
    this.otherControllers,
  });

  final TextEditingController controller;
  final List<TextEditingController>? otherControllers;

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
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    controller.clear();
                    if (otherControllers != null) {
                      for (final TextEditingController otherController in otherControllers!) {
                        otherController.clear();
                      }
                    }
                  },
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
