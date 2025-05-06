import 'package:flutter/material.dart';

class ProgressSteps extends StatelessWidget {
  const ProgressSteps({
    super.key,
    this.currentStep = 1,
    this.totalSteps = 3,
  });
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(
        totalSteps,
        (int index) {
          final int stepNumber = index + 1;
          final bool isActive = stepNumber <= currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
        },
      ),
    );
  }
}
