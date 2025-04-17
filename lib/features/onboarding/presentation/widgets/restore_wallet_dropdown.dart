import 'package:flutter/material.dart';

// A rounded dropdown for selecting how to restore a wallet.
// Displays the selectedMethod within a pill-shaped container and notifies onChanged when the user picks a different entry.
class RestoreMethodDropdown extends StatelessWidget {

  // Creates a restore-method dropdown.
  // ignore: use_super_parameters
  const RestoreMethodDropdown({
    required this.selectedMethod,
    required this.onChanged,
    Key? key,
  }) : super(key: key); // constructor

  // The currently selected restore method (e.g. "Seed Phrase").
  final String selectedMethod;

  // Called whenever the user selects a new method.
  final ValueChanged<String?> onChanged;

  // Hardcoded list of restore methods.
  static const List<String> _methods = <String>['Seed Phrase', 'Private Key'];


  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(40);
    final Color borderColor = Theme.of(context).dividerColor;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: borderRadius,
      ), 
      child: DropdownButton<String>(
        value: selectedMethod,
        isExpanded: true,
        isDense: true,
        alignment: AlignmentDirectional.centerEnd,
        underline: const SizedBox.shrink(),
        iconSize: 20,
        dropdownColor: Colors.white,
        items: _methods.map((String method) {
          return DropdownMenuItem<String>(
            value: method,
            child: Text(
              method,
              style: Theme.of(context).textTheme.bodyMedium,
            ), // Text
          ); 
        }).toList(), // items
        onChanged: onChanged,
      ),
    );
  }
} // RestoreMethodDropdown
