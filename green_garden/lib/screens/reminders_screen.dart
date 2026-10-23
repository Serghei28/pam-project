import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/reminder.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/water_plant.dart';
import '../models/watering_log_model.dart';
import '../utils/dates.dart';
import '../widgets/error_view.dart';
import '../widgets/refresh_button.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/section_title.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Экрану нужны обе модели: сроки полива — из растений,
    // уход — из напоминаний (а имена растений — снова из растений).
    final plants = context.watch<PlantsModel>();
    final reminders = context.watch<ReminderModel>();

    final Widget body;
    if (plants.isLoading || reminders.isLoading) {
      // 1) грузится — пока не готова хотя бы одна модель
      body = const Center(child: CircularProgressIndicator());
    } else if ((plants.error ?? reminders.error) case final error?) {
      // 2) ошибка — «Повторить» перезагружает только упавшие модели
      body = ErrorView(
        message: error,
        onRetry: () {
          if (plants.error != null) context.read<PlantsModel>().load();
          if (reminders.error != null) context.read<ReminderModel>().load();
        },
      );
    } else {
      // 3) данные
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionTitle('Полив'),
          _WateringSection(),
          _CareSection(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        centerTitle: true,
        actions: [
          RefreshButton(
            isLoading: plants.isLoading || reminders.isLoading,
            onRefresh: () {
              context.read<PlantsModel>().load();
              context.read<ReminderModel>().load();
            },
          ),
        ],
      ),
      body: body,
    );
  }
}

// Сроки полива ВЫЧИСЛЯЮТСЯ из интервала каждого растения —
// отдельно они нигде не хранятся. Нажатие = отметить полив.
// Состояния «грузится / ошибка» уже обработаны экраном выше.
class _WateringSection extends StatelessWidget {
  const _WateringSection();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<PlantsModel>();

    if (model.plants.isEmpty) return const Text('Растений пока нет');

    // ближайший срок полива сверху
    final plants = [...model.plants]
      ..sort((a, b) => a.nextWateringAt.compareTo(b.nextWateringAt));

    return Column(
      children: [
        for (final plant in plants)
          ReminderTile(
            // ключ из данных: состояние «идёт операция» привязано к растению,
            // а не к позиции в списке (список пересортируется после полива)
            key: ValueKey('water-${plant.id}'),
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
// Сюда попадаем, только когда обе модели загружены без ошибок,
// поэтому «растение удалено» не появится раньше времени.
class _CareSection extends StatelessWidget {
  const _CareSection();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ReminderModel>();
    final plants = context.watch<PlantsModel>();

    Widget tile(Reminder r) {
      final plantName = plants.byId(r.plantId)?.name ?? 'растение удалено';
      return ReminderTile(
        key: ValueKey('care-${r.id}'), // строка переезжает между разделами
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
