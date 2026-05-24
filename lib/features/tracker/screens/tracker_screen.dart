import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_tab.dart';

/// Owned by Member 2 (Daily Nutrition Tracker).
class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderTab(
      title: 'Tracker Harian',
      icon: Icons.restaurant,
      owner: 'Anggota 2',
      description:
          'Jurnal makan harian: pilih dari Koleksi Makananku, hitung total kalori & makronutrien per hari.',
    );
  }
}
