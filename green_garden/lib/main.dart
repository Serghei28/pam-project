import 'package:flutter/material.dart';

import 'screens/screens_menu.dart';

void main() {
  runApp(const GreenGardenApp());
}

class GreenGardenApp extends StatelessWidget {
  const GreenGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenGarden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const ScreensMenu(),
    );
  }
}