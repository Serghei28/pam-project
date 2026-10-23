import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/plant.dart';
import '../models/plants_model.dart';
import '../utils/dates.dart';
import '../widgets/delete_background.dart';
import '../widgets/delete_plant_dialog.dart';
import '../widgets/error_view.dart';
import '../widgets/plant_card.dart';
import '../widgets/refresh_button.dart';

class PlantsScreen extends StatelessWidget {
  const PlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch в build: при любом изменении модели экран перерисуется
    final model = context.watch<PlantsModel>();

    // Три состояния — все на виду
    final Widget body;
    if (model.isLoading) {
      body = const Center(child: CircularProgressIndicator()); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
        message: model.error!, // 2) ошибка
        onRetry: () => context.read<PlantsModel>().load(), // read: действие
      );
    } else {
      body = _PlantList(plants: model.plants); // 3) данные
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои растения'),
        centerTitle: true,
        actions: [
          RefreshButton(
            isLoading: model.isLoading,
            onRefresh: () => context.read<PlantsModel>().load(),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plants/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}

// Список растений с поиском (из L3)
class _PlantList extends StatelessWidget {
  final List<Plant> plants;

  const _PlantList({required this.plants});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SearchBar(
            hintText: 'Поиск растений',
            leading: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: plants.isEmpty
              ? const Center(child: Text('Растений пока нет'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    // Свайп влево → диалог → удаление через модель.
                    // Ключ — id из данных (не UniqueKey).
                    return Dismissible(
                      key: ValueKey(plant.id),
                      direction: DismissDirection.endToStart,
                      background: const DeleteBackground(bottomMargin: 12),
                      // false (отмена или ошибка) → карточка возвращается
                      confirmDismiss: (_) =>
                          deletePlantWithConfirm(context, plant),
                      child: PlantCard(
                        name: plant.name,
                        species: plant.species,
                        lastWatered: daysAgoText(plant.lastWateredAt),
                        isWatered: !plant.needsWatering,
                        onTap: () => context.push('/plants/${plant.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
