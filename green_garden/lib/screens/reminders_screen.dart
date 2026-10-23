import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/reminder.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/water_plant.dart';
import '../models/watering_log_model.dart';
import '../utils/dates.dart';
import '../widgets/error_view.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/section_title.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionTitle('Полив'),
          _WateringSection(),
          _CareSection(),
        ],
      ),
    );
  }
}

// Сроки полива ВЫЧИСЛЯЮТСЯ из интервала каждого растения —
// отдельно они нигде не хранятся. Нажатие = отметить полив.
class _WateringSection extends StatelessWidget {
  const _WateringSection();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PlantsModel>();

    if (model.isLoading) return const _Loading();
    if (model.error != null) {
      return ErrorView(
        message: model.error!,
        onRetry: () => context.read<PlantsModel>().load(),
      );
    }

    // ближайший срок полива сверху
    final plants = [...model.plants]
      ..sort((a, b) => a.nextWateringAt.compareTo(b.nextWateringAt));

    return Column(
      children: [
        for (final plant in plants)
          ReminderTile(
            title: 'Полить: ${plant.name}',
            dueText: dueText(plant.nextWateringAt),
            isOverdue: daysFromToday(plant.nextWateringAt) < 0,
            icon: Icons.water_drop_outlined,
            onTap: () async {
              final error = await waterPlant(
                plants: context.read<PlantsModel>(),
                logs: context.read<WateringLogModel>(),
                plantId: plant.id,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Полив отмечен: ${plant.name}'),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Уход (протереть, подкормить…) — из ReminderModel.
// Нажатие = отметить выполненным / вернуть в невыполненные.
class _CareSection extends StatelessWidget {
  const _CareSection();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ReminderModel>();
    final plants = context.watch<PlantsModel>();

    if (model.isLoading) {
      return const Column(children: [SectionTitle('Уход'), _Loading()]);
    }
    if (model.error != null) {
      return Column(
        children: [
          const SectionTitle('Уход'),
          ErrorView(
            message: model.error!,
            onRetry: () => context.read<ReminderModel>().load(),
          ),
        ],
      );
    }

    Widget tile(Reminder r) {
      final plantName = plants.byId(r.plantId)?.name ?? 'растение удалено';
      return ReminderTile(
        title: '${r.type.label}: $plantName',
        dueText: r.isDone ? formatDate(r.dueDate) : dueText(r.dueDate),
        isDone: r.isDone,
        isOverdue: r.isOverdue,
        icon: reminderIcon(r.type),
        onTap: () async {
          final error = await context.read<ReminderModel>().toggleDone(r.id);
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(error)));
          }
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Уход'),
        if (model.pending.isEmpty) const Text('Всё сделано'),
        for (final r in model.pending) tile(r),
        if (model.done.isNotEmpty) ...[
          const SectionTitle('Выполненные'),
          for (final r in model.done) tile(r),
        ],
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
