import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/plants_model.dart';
import '../utils/dates.dart';
import '../widgets/plant_card.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch в build: при любом изменении модели список перерисуется
    final plants = context.watch<PlantsModel>().plants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои растения'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Поиск растений',
              leading: Icon(Icons.search),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: plants.length,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return PlantCard(
                  name: plant.name,
                  species: plant.species,
                  lastWatered: daysAgoText(plant.lastWateredAt),
                  isWatered: !plant.needsWatering,
                  onTap: () => context.push('/plants/${plant.id}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plants/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}