import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/care_tasks.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: _DueBadge(child: Icon(Icons.local_florist_outlined)),
            selectedIcon: _DueBadge(child: Icon(Icons.local_florist)),
            label: 'Растения',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Журнал',
          ),
          NavigationDestination(
            icon: _CareBadge(child: Icon(Icons.notifications_outlined)),
            selectedIcon: _CareBadge(child: Icon(Icons.notifications)),
            label: 'Напоминания',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// Бейдж «сколько растений пора полить».
// Consumer — один «живой угол»: при notifyListeners перерисовывается
// только бейдж, а не весь AppShell.
class _DueBadge extends StatelessWidget {
  final Widget child;

  const _DueBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantsModel>(
      builder: (context, model, child) => Badge(
        isLabelVisible: model.dueCount > 0,
        label: Text('${model.dueCount}'),
        child: child,
      ),
      child: child,
    );
  }
}

// Бейдж «дел по уходу» — то же число, что в статистике профиля.
// Consumer2 перерисовывает только бейдж при изменении любой из двух моделей.
class _CareBadge extends StatelessWidget {
  final Widget child;

  const _CareBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlantsModel, ReminderModel>(
      builder: (context, plants, reminders, child) {
        final count = careTaskCount(plants, reminders);
        return Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: child,
        );
      },
      child: child,
    );
  }
}
