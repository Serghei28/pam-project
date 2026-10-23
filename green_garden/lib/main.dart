import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_plant_repository.dart';
import 'models/plants_model.dart';
import 'router.dart';

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
void main() {
  final plantRepository = MockPlantRepository(); // на L5: http-вариант

  runApp(
    MultiProvider(
      providers: [
        // Леса для переключателя «Симулировать сбой сети» — исчезнут на L5.
        // Repository не ChangeNotifier, поэтому простой Provider.value.
        Provider<MockPlantRepository>.value(value: plantRepository),
        // Модель — через фабрику; ..load() запускает первую загрузку.
        ChangeNotifierProvider(
          create: (_) => PlantsModel(plantRepository)..load(),
        ),
      ],
      child: const GreenGardenApp(), // MaterialApp.router — как на L3
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
