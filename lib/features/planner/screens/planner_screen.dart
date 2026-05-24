import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_tab.dart';

/// Owned by Member 3 (Meal Planner & Reminder).
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Meal Planner',
      icon: Icons.calendar_month,
      owner: 'Anggota 3',
      description:
          'Atur rencana makan + push notification pengingat lewat FCM / local notifications.',
    );
  }
}
