import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/plant.dart';
import '../models/delete_plant.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/watering_log_model.dart';

// Удаление растения: диалог подтверждения (как на L3) → каскадное удаление
// через модели (deletePlant) → SnackBar с результатом.
// Возвращает true, если само растение удалено.
// Используется в карточке (кнопка) и в списке (свайп).
Future<bool> deletePlantWithConfirm(BuildContext context, Plant plant) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Удалить «${plant.name}»?'),
      content: const Text(
        'Растение, его напоминания и история поливов будут удалены.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;

  final plants = context.read<PlantsModel>();
  final error = await deletePlant(
    plants: plants,
    reminders: context.read<ReminderModel>(),
    logs: context.read<WateringLogModel>(),
    plantId: plant.id,
  );
  // Растение удалено, если его больше нет в модели
  // (даже если потом не удалились связанные данные).
  final deleted = plants.byId(plant.id) == null;
  if (!context.mounted) return deleted; // экран мог закрыться

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Удалено: ${plant.name}')),
  );
  return deleted;
}
