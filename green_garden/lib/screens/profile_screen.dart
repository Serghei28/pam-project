import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/watering_log_model.dart';
import '../widgets/error_view.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Чтобы продолжить, нужно будет войти снова.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Да, выйти'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      context.go('/login'); // go: раздел с вкладками уходит из стека
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                Icons.person,
                size: 56,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Анна Садовая',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'anna@example.com',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          const _Stats(),
          const SizedBox(height: 24),

          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Редактировать профиль'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Уведомления'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('О приложении'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Выйти'),
            ),
          ),
        ],
      ),
    );
  }
}

// Статистика считается из моделей — цифр в коде больше нет
class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantsModel>();
    final logs = context.watch<WateringLogModel>();
    final reminders = context.watch<ReminderModel>();

    // 1) грузится — пока хотя бы одна модель загружается
    if (plants.isLoading || logs.isLoading || reminders.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 2) ошибка — «Повторить» перезагружает только упавшие модели
    final error = plants.error ?? logs.error ?? reminders.error;
    if (error != null) {
      return ErrorView(
        message: error,
        onRetry: () {
          if (plants.error != null) context.read<PlantsModel>().load();
          if (logs.error != null) context.read<WateringLogModel>().load();
          if (reminders.error != null) context.read<ReminderModel>().load();
        },
      );
    }

    // 3) данные
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${plants.plants.length}',
            label: 'Растений',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(value: '${logs.logs.length}', label: 'Поливов'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: '${plants.dueCount + reminders.pending.length}',
            label: 'Дел по уходу',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}