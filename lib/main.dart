import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const SoundSyncApp());
}

class SoundSyncApp extends StatelessWidget {
  const SoundSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}