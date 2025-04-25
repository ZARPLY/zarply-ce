import 'package:flutter/material.dart';

class RestoreMethodDropdown extends StatelessWidget {
  
    const RestoreMethodDropdown({
    required this.selectedMethod,
    required this.onChanged,
    super.key,
  }); 

  final String selectedMethod;

  final ValueChanged<String?> onChanged;

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
            ),
          ); 
        }).toList(), 
        onChanged: onChanged,
      ),
    );
  }
}
