import 'package:flutter/material.dart';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: const [
          // Строка поиска (пока статическая)
          SearchBar(
            hintText: 'Поиск растений',
            leading: Icon(Icons.search),
          ),
          SizedBox(height: 16),

          // Растения с «зашитыми» данными
          PlantCard(
            name: 'Монстера',
            species: 'Monstera deliciosa',
            lastWatered: 'Сегодня',
            isWatered: true,
          ),
          PlantCard(
            name: 'Фикус Бенджамина',
            species: 'Ficus benjamina',
            lastWatered: '6 дней назад',
            isWatered: false,
          ),
          PlantCard(
            name: 'Алоэ',
            species: 'Aloe vera',
            lastWatered: '3 дня назад',
            isWatered: true,
          ),
          PlantCard(
            name: 'Орхидея',
            species: 'Phalaenopsis',
            lastWatered: '8 дней назад',
            isWatered: false,
          ),
          PlantCard(
            name: 'Замиокулькас',
            species: 'Zamioculcas zamiifolia',
            lastWatered: 'Вчера',
            isWatered: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Пока экран статический: кнопка ничего не делает
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}