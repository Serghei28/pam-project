import 'package:green_garden/data/mock_plant_repository.dart';
import 'package:green_garden/data/mock_reminder_repository.dart';
import 'package:green_garden/data/mock_watering_log_repository.dart';

// Mock-хранилища без задержки — тесты не ждут по 800 мс на каждый вызов
MockPlantRepository fastPlantRepo() =>
    MockPlantRepository()..latency = Duration.zero;

MockWateringLogRepository fastLogRepo() =>
    MockWateringLogRepository()..latency = Duration.zero;

MockReminderRepository fastReminderRepo() =>
    MockReminderRepository()..latency = Duration.zero;
