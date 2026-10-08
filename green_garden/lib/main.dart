import 'package:flutter/material.dart';

import 'screens/app_drawer.dart';
import 'screens/splash_screen.dart';

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
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      builder: (context, child) {
        final colors = Theme.of(context).colorScheme;

        return ValueListenableBuilder<int>(
          valueListenable: currentScreenIndex,
          builder: (context, screenIndex, _) {
            // Стартовый экран показываем на всю ширину
            if (screenIndex < 0) return child!;

            if (isWideScreen(context)) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSidebar(),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Container(
                      color: colors.surface,
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Container(
              color: colors.surfaceContainerHighest,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            );
          },
        );
      },
      home: const SplashScreen(),
    );
  }
}