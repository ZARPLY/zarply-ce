import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded shape
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          icon: const Icon(Icons.person, color: Colors.black),
          label: const Text(
            "Contact",
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded shape
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
          label: const Text(
            "Scan QR",
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), // Rounded shape
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          icon: const Icon(Icons.more_horiz, color: Colors.black),
          label: const Text(
            "More",
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
