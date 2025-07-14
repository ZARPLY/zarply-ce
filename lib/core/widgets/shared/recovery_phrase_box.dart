import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class RecoveryPhraseBox extends StatelessWidget {
  const RecoveryPhraseBox({
    required this.words,
    required this.obscure,
    required this.onToggleVisibility,
    super.key,
  });

  final List<String> words;
  final bool obscure;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD3D9DF)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: obscure ? 4 : 0,
                  sigmaY: obscure ? 4 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: words
                        .map((String w) => Text(w, style: textStyle))
                        .toList(),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFD3D9DF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Center(
                child: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: onToggleVisibility,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
