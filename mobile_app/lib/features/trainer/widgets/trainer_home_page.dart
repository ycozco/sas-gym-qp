import 'package:flutter/material.dart';
import '../../../data/gym_state.dart';
import '../../../models/gym_models.dart';
import 'trainer_members_list.dart';

class TrainerHomePage extends StatelessWidget {
  const TrainerHomePage({
    super.key,
    required this.palette,
    required this.state,
    required this.onGo,
  });

  final RolePalette palette;
  final GymState state;
  final Function(String, [Map<String, dynamic>?]) onGo;

  @override
  Widget build(BuildContext context) {
    return TrainerMembersList(palette: palette, state: state, onGo: onGo);
  }
}
