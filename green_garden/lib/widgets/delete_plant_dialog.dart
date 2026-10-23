import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/plant.dart';
import '../models/plants_model.dart';

// Удаление растения: диалог подтверждения (как на L3) → удаление через
// модель → SnackBar с результатом. Возвращает true, если растение удалено.
// Используется в карточке (кнопка) и в списке (свайп).
Future<bool> deletePlantWithConfirm(BuildContext context, Plant plant) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text('Удалить «${plant.name}»?'),
      content: const Text('Растение исчезнет из списка и напоминаний.'),
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

  final error = await context.read<PlantsModel>().remove(plant.id);
  if (!context.mounted) return error == null; // экран мог закрыться

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error ?? 'Удалено: ${plant.name}')),
  );
  return error == null;
}
