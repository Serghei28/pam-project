import 'package:flutter/material.dart';

import '../widgets/section_title.dart';
import '../widgets/status_badge.dart';
import 'app_drawer.dart';

class PlantCardScreen extends StatelessWidget {
  const PlantCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: appDrawer(context, 2),
      appBar: AppBar(
        title: const Text('Карточка растения'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Пока экран статический: кнопка ничего не делает
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Фото (пока заглушка)
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

          // Название, вид и статус
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Монстера',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Monstera deliciosa', style: textTheme.bodyLarge),
                  ],
                ),
              ),
              const StatusBadge(isWatered: true),
            ],
          ),
          const SizedBox(height: 16),

          // Интервал и последний полив
          const Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.schedule,
                  label: 'Интервал полива',
                  value: 'Каждые 7 дней',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Последний полив',
                  value: 'Сегодня',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              // Пока экран статический: кнопка ничего не делает
            },
            icon: const Icon(Icons.water_drop),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Отметить полив'),
            ),
          ),

          // История поливов
          const SectionTitle('История поливов'),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.water_drop_outlined),
                  title: Text('7 октября 2026, 09:00'),
                  subtitle: Text('Земля была сухая'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined),
                  title: Text('30 сентября 2026, 09:15'),
                  subtitle: Text('Полила в обычном режиме'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.water_drop_outlined),
                  title: Text('23 сентября 2026, 08:50'),
                  subtitle: Text('Добавила подкормку'),
                ),
              ],
            ),
          ),

          // Напоминания
          const SectionTitle('Напоминания'),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Полить Монстеру'),
                  subtitle: Text('Срок: 14 октября 2026'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Протереть листья'),
                  subtitle: Text('Срок: 20 октября 2026'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Небольшая карточка с иконкой, подписью и значением
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