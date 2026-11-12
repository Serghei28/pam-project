import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      body = _PlantList(model: model); // 3) данные
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
      // Поиск над телом: не исчезает, пока грузится результат
      body: Column(
        children: [
          const _SearchField(),
          Expanded(child: body),
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

// Поиск (L5): происходит НА СЕРВЕРЕ — телефон получает только свой ломоть.
// Enter → load(search: q); крестик — сбросить фильтр.
class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _ctrl = TextEditingController(
    text: context.read<PlantsModel>().search, // фильтр живёт в модели
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _search(String query) =>
      context.read<PlantsModel>().load(search: query.trim());

  void _clear() {
    _ctrl.clear();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SearchBar(
        controller: _ctrl,
        hintText: 'Поиск растений',
        leading: const Icon(Icons.search),
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        trailing: [
          // ValueListenableBuilder: крестик появляется, как только есть текст
          ValueListenableBuilder(
            valueListenable: _ctrl,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Сбросить поиск',
                    onPressed: _clear,
                  ),
          ),
        ],
      ),
    );
  }
}

// Список растений: ломти с сервера, хвост просит следующую страницу
class _PlantList extends StatelessWidget {
  final PlantsModel model;

  const _PlantList({required this.model});

  @override
  Widget build(BuildContext context) {
    final plants = model.plants;
    if (plants.isEmpty) {
      return Center(
        child: Text(
          model.search.isEmpty ? 'Растений пока нет' : 'Ничего не найдено',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      // +1 — хвост списка, пока сервер, видимо, отдаёт ещё
      itemCount: plants.length + (model.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == plants.length) return _ListTail(model: model);
        final plant = plants[index];
        // Свайп влево → диалог → удаление через модель.
        // Ключ — id из данных (не UniqueKey).
        return Dismissible(
          key: ValueKey(plant.id),
          direction: DismissDirection.endToStart,
          background: const DeleteBackground(bottomMargin: 12),
          // false (отмена или ошибка) → карточка возвращается
          confirmDismiss: (_) => deletePlantWithConfirm(context, plant),
          child: PlantCard(
            name: plant.name,
            species: plant.species,
            lastWatered: daysAgoText(plant.lastWateredAt),
            isWatered: !plant.needsWatering,
            onTap: () => context.push('/plants/${plant.id}'),
          ),
        );
      },
    );
  }
}

// Хвост списка: просит следующую страницу и показывает маленький spinner.
// loadMore() стартует прямо отсюда, из build — потому внутри него нет
// синхронного notifyListeners() (см. PlantsModel.loadMore).
class _ListTail extends StatelessWidget {
  final PlantsModel model;

  const _ListTail({required this.model});

  @override
  Widget build(BuildContext context) {
    final error = model.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: () => context.read<PlantsModel>().retryLoadMore(),
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }
    model.loadMore(); // guard внутри: повторный вызов ничего не сделает
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
