import 'package:flutter/material.dart';

class TutorialObjectiveData {
  const TutorialObjectiveData({
    required this.title,
    required this.instruction,
    required this.icon,
  });

  final String title;
  final String instruction;
  final IconData icon;
}

const List<TutorialObjectiveData> tutorialObjectives = <TutorialObjectiveData>[
  TutorialObjectiveData(
    title: 'LEARN TO MOVE',
    instruction: 'Hold the left or right pad and move around.',
    icon: Icons.swap_horiz_rounded,
  ),
  TutorialObjectiveData(
    title: 'LEARN TO JUMP',
    instruction: 'Press JUMP while moving to clear an obstacle.',
    icon: Icons.keyboard_arrow_up_rounded,
  ),
  TutorialObjectiveData(
    title: 'COLLECT EVERY BIT',
    instruction: 'Gather all white bits. Spikes will send you back.',
    icon: Icons.diamond_outlined,
  ),
  TutorialObjectiveData(
    title: 'REACH THE EXIT',
    instruction: 'The door is open. Reach it to finish the tutorial.',
    icon: Icons.door_front_door_outlined,
  ),
];
