import 'package:flutter/material.dart';

import '../../models/profile.dart';

class WellbeingSection extends StatelessWidget {
  final Profile profile;
  const WellbeingSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.wellbeingLink.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.health_and_safety, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text('Wellbeing: ${profile.wellbeingLink}')),
      ],
    );
  }
}
