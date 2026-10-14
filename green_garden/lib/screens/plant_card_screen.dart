import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/section_title.dart';
import '../widgets/status_badge.dart';

class PlantCardScreen extends StatelessWidget {
  final int id;

  const PlantCardScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final plant = mockPlants.firstWhere((p) => p.id == id);

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
              StatusBadge(isWatered: plant.isWatered),
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
                  value: plant.lastWatered,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

                    FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Полив отмечен: ${plant.name}')),
              );
            },
            icon: const Icon(Icons.water_drop),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Отметить полив'),
            ),
          ),

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

          const SectionTitle('Напоминания'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text('Полить: ${plant.name}'),
                  subtitle: const Text('Срок: 14 октября 2026'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text('Протереть листья: ${plant.name}'),
                  subtitle: const Text('Срок: 20 октября 2026'),
                ),
              ],
            ),
          ),
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