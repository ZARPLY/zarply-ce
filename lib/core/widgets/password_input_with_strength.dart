import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/password_strength_provider.dart';
import '../services/password_strength_service.dart';
import 'password_strength_indicator.dart';

class PasswordInputWithStrength extends StatefulWidget {
  const PasswordInputWithStrength({
    required this.controller,
    super.key,
    this.labelText = 'Password',
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
    this.showSuggestions = true,
    this.showCriteria = false,
    this.compact = false,
    this.enableStrengthFeedback = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool showSuggestions;
  final bool showCriteria;
  final bool compact;
  final bool enableStrengthFeedback;

  @override
  State<PasswordInputWithStrength> createState() =>
      _PasswordInputWithStrengthState();
}

class _PasswordInputWithStrengthState extends State<PasswordInputWithStrength> {
  bool _obscureText = true;
  late PasswordStrengthProvider _strengthProvider;

  @override
  void initState() {
    super.initState();
    _strengthProvider = PasswordStrengthProvider();
    widget.controller.addListener(_onPasswordChanged);

    // Evaluate initial password if any
    if (widget.controller.text.isNotEmpty) {
      _strengthProvider.evaluatePassword(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPasswordChanged);
    _strengthProvider.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (widget.enableStrengthFeedback) {
      _strengthProvider.evaluatePassword(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PasswordStrengthProvider>.value(
      value: _strengthProvider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: _obscureText,
            textInputAction: widget.textInputAction,
            onSubmitted: (String value) {
              if (widget.onSubmitted != null) {
                widget.onSubmitted!(value);
              } else {
                FocusScope.of(context).nextFocus();
              }
            },
            style: const TextStyle(
              fontSize: 14,
            ),
            decoration: InputDecoration(
              labelText: widget.labelText,
              border: const OutlineInputBorder(),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorText: widget.errorText,
              errorMaxLines: 2,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (widget.enableStrengthFeedback &&
                      widget.controller.text.isNotEmpty)
                    Consumer<PasswordStrengthProvider>(
                      builder: (
                        BuildContext context,
                        PasswordStrengthProvider provider,
                        Widget? child,
                      ) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Icon(
                            _getStrengthIcon(provider),
                            color: provider.strengthColor,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (widget.enableStrengthFeedback)
            PasswordStrengthIndicator(
              showSuggestions: widget.showSuggestions,
              showCriteria: widget.showCriteria,
              compact: widget.compact,
            ),
        ],
      ),
    );
  }

  IconData _getStrengthIcon(PasswordStrengthProvider provider) {
    switch (provider.strength) {
      case PasswordStrength.weak:
        return Icons.warning;
      case PasswordStrength.medium:
        return Icons.info;
      case PasswordStrength.strong:
        return Icons.check_circle;
      case PasswordStrength.veryStrong:
        return Icons.verified;
    }
  }
}
