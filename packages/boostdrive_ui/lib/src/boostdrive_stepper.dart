import 'package:flutter/material.dart';

class BoostDriveStepper extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;
  final Color activeColor;
  final Color inactiveColor;

  const BoostDriveStepper({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    this.activeColor = const Color(0xFF16A34A),
    Color? inactiveColor,
  }) : inactiveColor = inactiveColor ?? const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: List.generate(stepTitles.length, (index) {
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            index <= currentStep ? activeColor : inactiveColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stepTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: index == currentStep
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: index <= currentStep
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != stepTitles.length - 1)
                  Container(
                    width: 20,
                    height: 2,
                    color: index < currentStep ? activeColor : inactiveColor,
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

