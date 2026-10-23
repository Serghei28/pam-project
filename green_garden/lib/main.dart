import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_data.dart';
import 'models/plants_model.dart';
import 'router.dart';

void main() {
  runApp(
    // Модель монтируется НАД router-ом: её видят все экраны.
    // create — фабрика: Provider создаёт модель сам и сам вызовет dispose.
    ChangeNotifierProvider(
      create: (_) => PlantsModel(mockPlants),
      child: const GreenGardenApp(),
    ),
  );
}

class GreenGardenApp extends StatelessWidget {
  const GreenGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GreenGarden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      routerConfig: router,
      builder: (context, child) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        );
      },
    );
  }
}
