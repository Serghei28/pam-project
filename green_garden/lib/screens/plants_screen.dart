import 'package:flutter/material.dart';
import 'app_drawer.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            drawer: appDrawer(context, 1),
      appBar: AppBar(
        title: const Text('Мои растения'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: const [
          SearchBar(
            hintText: 'Поиск растений',
            leading: Icon(Icons.search),
          ),
          SizedBox(height: 16),

          _PlantCard(
            name: 'Монстера',
            species: 'Monstera deliciosa',
            lastWatered: 'Сегодня',
            isWatered: true,
          ),
          _PlantCard(
            name: 'Фикус Бенджамина',
            species: 'Ficus benjamina',
            lastWatered: '6 дней назад',
            isWatered: false,
          ),
          _PlantCard(
            name: 'Алоэ',
            species: 'Aloe vera',
            lastWatered: '3 дня назад',
            isWatered: true,
          ),
          _PlantCard(
            name: 'Орхидея',
            species: 'Phalaenopsis',
            lastWatered: '8 дней назад',
            isWatered: false,
          ),
          _PlantCard(
            name: 'Замиокулькас',
            species: 'Zamioculcas zamiifolia',
            lastWatered: 'Вчера',
            isWatered: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  final String name;
  final String species;
  final String lastWatered;
  final bool isWatered;

  const _PlantCard({
    required this.name,
    required this.species,
    required this.lastWatered,
    required this.isWatered,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Color chipBackground =
        isWatered ? Colors.green.shade100 : Colors.orange.shade100;
    final Color chipText =
        isWatered ? Colors.green.shade900 : Colors.orange.shade900;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.local_florist, color: colors.onPrimaryContainer),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(species),
              const SizedBox(height: 4),
              Text('Полито: $lastWatered'),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isWatered ? 'Полито' : 'Пора поливать',
            style: TextStyle(
              color: chipText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}