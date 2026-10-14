import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/plant_card.dart';
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
              itemCount: mockPlants.length,
              itemBuilder: (context, index) {
                final plant = mockPlants[index];
                return PlantCard(
                  name: plant.name,
                  species: plant.species,
                  lastWatered: plant.lastWatered,
                  isWatered: plant.isWatered,
                );
              },
            ),
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