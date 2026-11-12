import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/api_client.dart';
import 'data/auth_api.dart';
import 'data/files_api.dart';
import 'data/http_plant_repository.dart';
import 'data/http_reminder_repository.dart';
import 'data/http_watering_log_repository.dart';
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

  // L5: mock умер — данные идут с сервера. 401 → login, в одном месте.
  final api = ApiClient(
    apiBase,
    tokens,
    onUnauthorized: () => router.go('/login'),
  );
  final plantRepository = HttpPlantRepository(api);
  final wateringLogRepository = HttpWateringLogRepository(api);
  final reminderRepository = HttpReminderRepository(api);

  runApp(
    MultiProvider(
      providers: [
        // register/login/logout; его читает экран входа и профиль
        Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
        // загрузка фото (POST /files) и адреса для Image.network
        Provider<FilesApi>(create: (_) => FilesApi(api)),
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
