import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/planner/screens/planner_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/scanner/screens/scanner_home_screen.dart';
import '../../features/tracker/screens/tracker_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1;

  static const _tabs = <Widget>[
    TrackerScreen(),
    ScannerHomeScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  static const _icons = [
    (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Tracker'),
    (Icons.document_scanner_outlined, Icons.document_scanner_rounded, 'Scanner'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Rencana'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        items: _icons,
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<(IconData, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xF5FFFFFF),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFFFFF)),
            boxShadow: AppTheme.floatingShadow,
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final (outlineIcon, filledIcon, label) = items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDestinationSelected(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: selected
                        ? AppTheme.gradientButtonDecoration(radius: 24)
                        : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? filledIcon : outlineIcon,
                          size: 22,
                          color: selected ? Colors.white : AppTheme.textMuted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: AppTheme.inter(
                            size: 10,
                            color: selected ? Colors.white : AppTheme.textMuted,
                            weight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
