import 'package:flutter/material.dart';

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.type = LoadingButtonType.elevated,
    this.style,
    this.loadingColor,
    this.loadingSize = 20.0,
    this.loadingStrokeWidth = 2.0,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final LoadingButtonType type;
  final ButtonStyle? style;
  final Color? loadingColor;
  final double loadingSize;
  final double loadingStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final Widget loadingIndicator = SizedBox(
      height: loadingSize,
      width: loadingSize,
      child: CircularProgressIndicator(
        strokeWidth: loadingStrokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          loadingColor ?? Colors.blue,
        ),
      ),
    );

    final Widget buttonChild = isLoading ? loadingIndicator : child;
    final VoidCallback? buttonOnPressed = isLoading ? null : onPressed;

    switch (type) {
      case LoadingButtonType.elevated:
        return ElevatedButton(
          onPressed: buttonOnPressed,
          style: style,
          child: buttonChild,
        );
      case LoadingButtonType.text:
        return TextButton(
          onPressed: buttonOnPressed,
          style: style,
          child: buttonChild,
        );
      case LoadingButtonType.outlined:
        return OutlinedButton(
          onPressed: buttonOnPressed,
          style: style,
          child: buttonChild,
        );
    }
  }
}

/// The type of button to display.
enum LoadingButtonType {
  /// An elevated button with a filled background.
  elevated,

  /// A text button with no background.
  text,

  /// An outlined button with a border but no filled background.
  outlined,
}
