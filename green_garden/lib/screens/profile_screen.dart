import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_plant_repository.dart';
import '../data/mock_reminder_repository.dart';
import '../data/mock_watering_log_repository.dart';
import '../models/care_tasks.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/watering_log_model.dart';
import '../widgets/error_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Положение переключателя — эфемерное состояние экрана → setState (C7)
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    // Если экран пересоздан, показываем текущее состояние «аварии»
    _simulateError = context.read<MockPlantRepository>().simulateError;
  }

  // Леса демонстрации аварии: ЕДИНСТВЕННОЕ место UI, которое знает о mock-ах.
  // На L5 вместе с mock-ами исчезнет и этот переключатель.
  void _setSimulateError(bool value) {
    setState(() => _simulateError = value);
    context.read<MockPlantRepository>().simulateError = value;
    context.read<MockWateringLogRepository>().simulateError = value;
    context.read<MockReminderRepository>().simulateError = value;
  }

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

          // Эти разделы появятся позже (профиль — с backend-ом на L5),
          // поэтому пункты неактивны, а не «нажимаются впустую»
          const Card(
            child: Column(
              children: [
                ListTile(
                  enabled: false,
                  leading: Icon(Icons.person_outline),
                  title: Text('Редактировать профиль'),
                  subtitle: Text('Скоро'),
                ),
                Divider(height: 1),
                ListTile(
                  enabled: false,
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Уведомления'),
                  subtitle: Text('Скоро'),
                ),
                Divider(height: 1),
                ListTile(
                  enabled: false,
                  leading: Icon(Icons.info_outline),
                  title: Text('О приложении'),
                  subtitle: Text('Скоро'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.cloud_off_outlined),
              title: const Text('Симулировать сбой сети'),
              subtitle: const Text('Все запросы к данным вернут ошибку'),
              value: _simulateError,
              onChanged: _setSimulateError,
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
            value: '${careTaskCount(plants, reminders)}',
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