import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/plant.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/water_plant.dart';
import '../models/watering_log_model.dart';
import '../utils/dates.dart';
import '../widgets/async_action.dart';
import '../widgets/delete_plant_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/not_found_view.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/section_title.dart';
import '../widgets/status_badge.dart';

class PlantCardScreen extends StatelessWidget {
  final int id;

  const PlantCardScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    // watch в build: после «Отметить полив» карточка обновится сама.
    final model = context.watch<PlantsModel>();
    final plant = model.byId(id);

    // У null три смысла: список ещё грузится, загрузка упала,
    // или список загружен, а такого id нет (старая ссылка, удалённое растение).
    if (plant == null) {
      final Widget body;
      if (model.isLoading) {
        body = const Center(child: CircularProgressIndicator());
      } else if (model.error != null) {
        body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<PlantsModel>().load(),
        );
      } else {
        body = const NotFoundView(message: 'Растение не найдено');
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Карточка растения'),
          centerTitle: true,
        ),
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка растения'),
        centerTitle: true,
        actions: [
          // Форма редактирования ещё не сделана — кнопка честно неактивна
          const IconButton(
            icon: Icon(Icons.edit_outlined),
            tooltip: 'Редактирование — скоро',
            onPressed: null,
          ),
          _DeleteButton(plant: plant),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PlantPhoto(),
          const SizedBox(height: 16),
          _PlantHeader(plant: plant),
          const SizedBox(height: 16),
          _PlantInfo(plant: plant),
          const SizedBox(height: 16),
          _WaterButton(plant: plant),
          const SectionTitle('История поливов'),
          _WateringHistory(plantId: plant.id),
          const SectionTitle('Напоминания'),
          // срок полива вычисляется из интервала
          ReminderTile(
            title: 'Полить',
            dueText: dueText(plant.nextWateringAt),
            isOverdue: daysFromToday(plant.nextWateringAt) < 0,
            icon: Icons.water_drop_outlined,
          ),
          _CareReminders(plantId: plant.id),
        ],
      ),
    );
  }
}

// Удаление: диалог → каскадное удаление → уход с экрана.
// Пока идёт удаление, кнопка неактивна — второй диалог не открыть.
class _DeleteButton extends StatelessWidget {
  final Plant plant;

  const _DeleteButton({required this.plant});

  @override
  Widget build(BuildContext context) {
    return AsyncAction(
      action: () async {
        final deleted = await deletePlantWithConfirm(context, plant);
        // растения больше нет — его экран уходит из стека
        if (deleted && context.mounted) context.pop();
      },
      builder: (context, busy, run) => IconButton(
        icon: busy ? const SmallSpinner() : const Icon(Icons.delete_outline),
        tooltip: 'Удалить',
        onPressed: run,
      ),
    );
  }
}

// Фото растения (пока иконка — загрузка фото появится на L5)
class _PlantPhoto extends StatelessWidget {
  const _PlantPhoto();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.local_florist,
        size: 96,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

// Название, вид и статус полива
class _PlantHeader extends StatelessWidget {
  final Plant plant;

  const _PlantHeader({required this.plant});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.name,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (plant.species.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(plant.species, style: textTheme.bodyLarge),
              ],
            ],
          ),
        ),
        StatusBadge(isWatered: !plant.needsWatering),
      ],
    );
  }
}

// Интервал полива и дата последнего полива
class _PlantInfo extends StatelessWidget {
  final Plant plant;

  const _PlantInfo({required this.plant});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule,
            label: 'Интервал полива',
            value: 'Каждые ${plant.wateringIntervalDays} дн.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            icon: Icons.water_drop_outlined,
            label: 'Последний полив',
            value: daysAgoText(plant.lastWateredAt),
          ),
        ),
      ],
    );
  }
}

// «Отметить полив». Пока полив сохраняется, кнопка неактивна —
// двойной записи в журнал не будет.
class _WaterButton extends StatelessWidget {
  final Plant plant;

  const _WaterButton({required this.plant});

  @override
  Widget build(BuildContext context) {
    return AsyncAction(
      action: () async {
        // read в callback-е: действие, без подписки.
        // Полив пишет и в журнал, и дату у растения.
        final error = await waterPlant(
          plants: context.read<PlantsModel>(),
          logs: context.read<WateringLogModel>(),
          plantId: plant.id,
        );
        // экран мог закрыться, пока «запрос» летел
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Полив отмечен: ${plant.name}')),
        );
      },
      builder: (context, busy, run) => FilledButton.icon(
        onPressed: run,
        icon: busy ? const SmallSpinner() : const Icon(Icons.water_drop),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(busy ? 'Сохранение…' : 'Отметить полив'),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// История поливов растения — из WateringLogModel, с тремя состояниями
class _WateringHistory extends StatelessWidget {
  final int plantId;

  const _WateringHistory({required this.plantId});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<WateringLogModel>();

    if (model.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (model.error != null) {
      return ErrorView(
        message: model.error!,
        onRetry: () => context.read<WateringLogModel>().load(),
      );
    }

    final logs = model.logsForPlant(plantId);
    if (logs.isEmpty) {
      return const Card(
        child: ListTile(title: Text('Поливов пока не было')),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final (i, log) in logs.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text(formatDateTime(log.date)),
              subtitle: log.note.isEmpty ? null : Text(log.note),
            ),
          ],
        ],
      ),
    );
  }
}

// Невыполненные напоминания об уходе за этим растением — из ReminderModel
class _CareReminders extends StatelessWidget {
  final int plantId;

  const _CareReminders({required this.plantId});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ReminderModel>();

    if (model.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (model.error != null) {
      return ErrorView(
        message: model.error!,
        onRetry: () => context.read<ReminderModel>().load(),
      );
    }

    return Column(
      children: [
        for (final r in model.pendingForPlant(plantId))
          ReminderTile(
            key: ValueKey('care-${r.id}'),
            title: r.type.label,
            dueText: dueText(r.dueDate),
            isOverdue: r.isOverdue,
            icon: reminderIcon(r.type),
            onTap: () async {
              final error =
                  await context.read<ReminderModel>().toggleDone(r.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
            },
          ),
      ],
    );
  }
}
