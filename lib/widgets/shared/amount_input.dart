import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AmountInput extends StatefulWidget {
  const AmountInput({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

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
      _displayController.text = _formatAmount(widget.controller.text);
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  String _formatAmount(String value) {
    if (value.isEmpty) return '';

    final int? cents = int.tryParse(value.replaceAll(RegExp('[^0-9]'), ''));
    if (cents == null) return '';

    final double rands = cents / 100;
    final NumberFormat formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
      locale: 'en_ZA',
    );
    return formatter.format(rands);
  }

  @override
  Widget build(BuildContext context) {
    final bool isInvalidAmount = widget.controller.text.isNotEmpty &&
        (int.tryParse(
                  widget.controller.text.replaceAll(RegExp('[^0-9]'), ''),
                ) ??
                0) <
            500;

    return TextField(
      controller: _displayController,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction(
          (TextEditingValue oldValue, TextEditingValue newValue) {
            if (newValue.text.isEmpty) {
              widget.controller.text = '';
              return newValue;
            }

            final String formatted = _formatAmount(newValue.text);
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
