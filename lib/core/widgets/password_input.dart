import 'package:flutter/material.dart';

class PasswordInput extends StatefulWidget {
  const PasswordInput({
    required this.controller,
    super.key,
    this.labelText = 'Password',
    this.errorText,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final void Function(String)? onChanged;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
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
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}
