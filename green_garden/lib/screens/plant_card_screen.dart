import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/water_plant.dart';
import '../models/watering_log_model.dart';
import '../utils/dates.dart';
import '../widgets/error_view.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/section_title.dart';
import '../widgets/status_badge.dart';

class PlantCardScreen extends StatelessWidget {
  final int id;

  const PlantCardScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        body = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: colors.outline),
              const SizedBox(height: 12),
              Text('Растение не найдено', style: textTheme.titleMedium),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/plants'),
                child: const Text('К списку растений'),
              ),
            ],
          ),
        );
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
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
          ),
          const SizedBox(height: 16),

          Row(
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
                    const SizedBox(height: 4),
                    Text(plant.species, style: textTheme.bodyLarge),
                  ],
                ),
              ),
              StatusBadge(isWatered: !plant.needsWatering),
            ],
          ),
          const SizedBox(height: 16),

          Row(
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
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () async {
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
                SnackBar(
                  content: Text(error ?? 'Полив отмечен: ${plant.name}'),
                ),
              );
            },
            icon: const Icon(Icons.water_drop),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Отметить полив'),
            ),
          ),

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
