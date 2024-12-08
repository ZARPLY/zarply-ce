import 'package:flutter/material.dart';

class ToggleBar extends StatefulWidget {
  const ToggleBar({super.key});

  @override
  _ToggleBarState createState() => _ToggleBarState();
}

class _ToggleBarState extends State<ToggleBar> {
  bool isZarpSelected = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isZarpSelected = true;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isZarpSelected ? Colors.white30 : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  const Image(image: AssetImage('images/zarp.jpeg')),
                  if (isZarpSelected) ...[
                    const SizedBox(width: 8.0),
                    const Text(
                      "ZARP",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: () {
              setState(() {
                isZarpSelected = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: !isZarpSelected ? Colors.white30 : Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  const Image(image: AssetImage('images/solana.png')),
                  if (!isZarpSelected) ...[
                    const SizedBox(width: 8.0),
                    const Text(
                      "SOL",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
