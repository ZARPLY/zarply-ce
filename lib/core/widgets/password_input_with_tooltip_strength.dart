import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/password_strength_provider.dart';

class PasswordInputWithTooltipStrength extends StatefulWidget {
  const PasswordInputWithTooltipStrength({
    required this.controller,
    super.key,
    this.labelText = 'Password',
    this.errorText,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
    this.enableStrengthFeedback = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enableStrengthFeedback;

  @override
  State<PasswordInputWithTooltipStrength> createState() =>
      _PasswordInputWithTooltipStrengthState();
}

class _PasswordInputWithTooltipStrengthState
    extends State<PasswordInputWithTooltipStrength> {
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
                        return Tooltip(
                          message: _buildTooltipMessage(provider),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.help_outline,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
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
            Consumer<PasswordStrengthProvider>(
              builder: (
                BuildContext context,
                PasswordStrengthProvider provider,
                Widget? child,
              ) {
                if (provider.result.message == 'Enter a password') {
                  return const SizedBox.shrink();
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildProgressBar(context, provider),
                      const SizedBox(height: 8),
                      _buildStrengthMessage(context, provider),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _buildTooltipMessage(PasswordStrengthProvider provider) {
    if (provider.suggestions.isEmpty) {
      return 'Password strength: ${provider.message}';
    }

    final String strengthInfo =
        'Strength: ${provider.message}\n\nSuggestions:\n';
    final String suggestions =
        provider.suggestions.take(3).map((String s) => '• $s').join('\n');
    return strengthInfo + suggestions;
  }

  Widget _buildProgressBar(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    const double barHeight = 4;
    const double spacing = 2;

    return Row(
      children: <Widget>[
        for (int i = 0; i < 4; i++) ...<Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: barHeight,
              decoration: BoxDecoration(
                color: i < provider.progressLevel
                    ? provider.progressColors[i < provider.progressColors.length
                        ? i
                        : provider.progressColors.length - 1]
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: spacing),
        ],
      ],
    );
  }

  Widget _buildStrengthMessage(
    BuildContext context,
    PasswordStrengthProvider provider,
  ) {
    return Row(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: provider.strengthColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: provider.strengthColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          child: Text(provider.message),
        ),
        const Spacer(),
        Text(
          '${(provider.score * 100).round()}%',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
