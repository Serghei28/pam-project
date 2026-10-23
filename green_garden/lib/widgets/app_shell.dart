import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/plants_model.dart';

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
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
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
