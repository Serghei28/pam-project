import 'package:flutter_test/flutter_test.dart';
import 'package:green_garden/data/mock_plant_repository.dart';
import 'package:green_garden/data/plant.dart';
import 'package:green_garden/data/result.dart';
import 'package:green_garden/models/delete_plant.dart';
import 'package:green_garden/models/delete_watering_log.dart';
import 'package:green_garden/models/plants_model.dart';
import 'package:green_garden/models/reminder_model.dart';
import 'package:green_garden/models/water_plant.dart';
import 'package:green_garden/models/watering_log_model.dart';

import 'helpers.dart';

// Хранилище, у которого ломается только update — для проверки отката
class _FailingUpdateRepository extends MockPlantRepository {
  _FailingUpdateRepository() {
    latency = Duration.zero;
  }

  @override
  Future<Result<Plant>> update(Plant plant) async => const Err('сбой update');
}

void main() {
  late PlantsModel plants;
  late WateringLogModel logs;
  late ReminderModel reminders;

  setUp(() async {
    plants = PlantsModel(fastPlantRepo());
    logs = WateringLogModel(fastLogRepo());
    reminders = ReminderModel(fastReminderRepo());
    await Future.wait([plants.load(), logs.load(), reminders.load()]);
  });

  test('полив: запись в журнале + новая дата у растения', () async {
    final before = logs.logsForPlant(2).length;
    expect(await waterPlant(plants: plants, logs: logs, plantId: 2), isNull);
    expect(logs.logsForPlant(2), hasLength(before + 1));
    expect(plants.byId(2)!.needsWatering, isFalse);
  });

  test(
    'полив: если растение не обновилось, запись журнала откатывается',
    () async {
      final failingPlants = PlantsModel(_FailingUpdateRepository());
      await failingPlants.load();
      final before = logs.logsForPlant(2).length;

      final error = await waterPlant(
        plants: failingPlants,
        logs: logs,
        plantId: 2,
      );

      expect(error, isNotNull);
      expect(logs.logsForPlant(2), hasLength(before)); // запись удалена
    },
  );

  test('удаление растения каскадно удаляет напоминания и журнал', () async {
    expect(reminders.pendingForPlant(1), isNotEmpty);
    expect(logs.logsForPlant(1), isNotEmpty);

    final error = await deletePlant(
      plants: plants,
      reminders: reminders,
      logs: logs,
      plantId: 1,
    );

    expect(error, isNull);
    expect(plants.byId(1), isNull);
    expect(reminders.reminders.where((r) => r.plantId == 1), isEmpty);
    expect(logs.logsForPlant(1), isEmpty);
  });

  test('удаление последней записи журнала пересчитывает дату полива', () async {
    // У Монстеры (id 1) три записи; удаляем самую новую
    final history = logs.logsForPlant(1);
    final latest = history.first;
    final previous = history[1];

    final error = await deleteWateringLog(
      plants: plants,
      logs: logs,
      log: latest,
    );

    expect(error, isNull);
    expect(plants.byId(1)!.lastWateredAt, previous.date);
  });
}
