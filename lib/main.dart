import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'root_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EvidenceEngineStudioOpenApp(),
    ),
  );
}

class EvidenceEngineStudioOpenApp extends StatelessWidget {
  const EvidenceEngineStudioOpenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvidenceEngineStudioOpen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const RootScreen(),
    );
  }
}
