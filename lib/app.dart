import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/main_shell.dart';

class GiziKuApp extends StatelessWidget {
  const GiziKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiziKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const MainShell(),
    );
  }
}
