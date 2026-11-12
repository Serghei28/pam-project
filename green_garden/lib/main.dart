import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth_api.dart';
import 'data/mock_plant_repository.dart';
import 'data/mock_reminder_repository.dart';
import 'data/mock_watering_log_repository.dart';
import 'data/token_store.dart';
import 'models/plants_model.dart';
import 'models/reminder_model.dart';
import 'models/watering_log_model.dart';
import 'router.dart';

// Адрес backend-а (server/). Chrome/десктоп — localhost; эмулятор Android
// не знает «localhost» ноутбука — там http://10.0.2.2:<порт>; телефон — IP
// ноутбука в сети. На этом ноутбуке 8080 занят, поэтому сервер на 8090
// (PORT=8090 ./gradlew bootRun). Другой адрес без правки кода:
// flutter run --dart-define=API_BASE=http://10.0.2.2:8090
const apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:8090',
);

// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs до runApp (C9)
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у
  router = createRouter(loggedIn: loggedIn);

  final plantRepository = MockPlantRepository(); // на L5: http-варианты
  final wateringLogRepository = MockWateringLogRepository();
  final reminderRepository = MockReminderRepository();

  runApp(
    MultiProvider(
      providers: [
        // register/login/logout; его читает экран входа и профиль
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
        // Леса для переключателя «Симулировать сбой сети» — исчезнут на L5.
        // Repository не ChangeNotifier, поэтому простой Provider.value.
        Provider<MockPlantRepository>.value(value: plantRepository),
        Provider<MockWateringLogRepository>.value(
          value: wateringLogRepository,
        ),
        Provider<MockReminderRepository>.value(value: reminderRepository),
        // Модель — через фабрику; ..load() запускает первую загрузку.
        ChangeNotifierProvider(
          create: (_) => PlantsModel(plantRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => WateringLogModel(wateringLogRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReminderModel(reminderRepository)..load(),
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
