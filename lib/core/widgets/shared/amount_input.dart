import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/formatters.dart';
import '../clear_icon_button.dart';

class AmountInput extends StatefulWidget {
  const AmountInput({
    required this.controller,
    this.readOnly = false,
    super.key,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final bool readOnly;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late final TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    if (widget.controller.text.isNotEmpty) {
      _displayController.text = Formatters.formatAmount(
        double.parse(widget.controller.text) / 100,
      ).replaceAll('R', '').trim();
    }
    _displayController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isInvalidAmount = widget.controller.text.isNotEmpty && (int.tryParse(widget.controller.text) ?? 0) < 500;

    return TextField(
      controller: _displayController,
      keyboardType: TextInputType.number,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted ?? (_) => FocusScope.of(context).nextFocus(),
      readOnly: widget.readOnly,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction(
          (TextEditingValue oldValue, TextEditingValue newValue) {
            if (newValue.text.isEmpty) {
              widget.controller.text = '';
              return newValue;
            }
            final int? cents = int.tryParse(newValue.text);
            if (cents == null) return oldValue;
            final double rands = cents / 100;
            final String formatted = Formatters.formatAmount(rands).replaceAll('R', '').trim();
            if (formatted.isEmpty) return oldValue;
            widget.controller.text = newValue.text;
            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          },
        ),
      ],
      style: const TextStyle(
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefix: const Text(
          'R ',
          style: TextStyle(fontSize: 14),
        ),
        suffixIcon: ClearIconButton(
          controller: _displayController,
          otherControllers: <TextEditingController>[widget.controller],
        ),
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.grey,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.blue,
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        labelText: 'Payment Amount',
        errorText: isInvalidAmount ? 'Amount must be at least R5' : null,
      ),
    );
  }
}
