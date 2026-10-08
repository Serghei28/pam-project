import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'plant_card_screen.dart';
import 'plant_form_screen.dart';
import 'plants_screen.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'watering_journal_screen.dart';

const double wideScreenWidth = 900;

bool isWideScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= wideScreenWidth;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final ValueNotifier<int> currentScreenIndex = ValueNotifier<int>(-1);

class _NavItem {
  final String title;
  final IconData icon;
  final Widget screen;

  const _NavItem(this.title, this.icon, this.screen);
}

const List<_NavItem> _items = [
  _NavItem('Вход / регистрация', Icons.login, LoginScreen()),
  _NavItem('Мои растения', Icons.local_florist, PlantsScreen()),
  _NavItem('Карточка растения', Icons.eco, PlantCardScreen()),
  _NavItem('Форма растения', Icons.edit_note, PlantFormScreen()),
  _NavItem('Журнал полива', Icons.water_drop, WateringJournalScreen()),
  _NavItem(
    'Напоминания',
    Icons.notifications_outlined,
    RemindersScreen(),
  ),
  _NavItem('Профиль', Icons.person_outline, ProfileScreen()),
];

void openScreen(int index) {
  currentScreenIndex.value = index;
  navigatorKey.currentState?.pushReplacement(
    MaterialPageRoute(builder: (context) => _items[index].screen),
  );
}

Widget? appDrawer(BuildContext context, int selectedIndex) {
  if (isWideScreen(context)) return null;
  return AppDrawer(selectedIndex: selectedIndex);
}

class AppDrawer extends StatelessWidget {
  final int selectedIndex;

  const AppDrawer({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        Navigator.of(context).pop(); // закрыть меню
        if (index == selectedIndex) return;
        openScreen(index);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Row(
            children: [
              Icon(Icons.local_florist, size: 32, color: colors.primary),
              const SizedBox(width: 12),
              Text(
                'GreenGarden',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        for (final item in _items)
          NavigationDrawerDestination(
            icon: Icon(item.icon),
            label: Text(item.title),
          ),
      ],
    );
  }
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      child: Material(
        color: colors.surfaceContainerLow,
        child: SafeArea(
          child: ValueListenableBuilder<int>(
            valueListenable: currentScreenIndex,
            builder: (context, selected, _) {
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 16, 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_florist,
                          size: 32,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'GreenGarden',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      child: ListTile(
                        leading: Icon(_items[i].icon),
                        title: Text(_items[i].title),
                        selected: i == selected,
                        selectedTileColor: colors.primaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        onTap: () {
                          if (i != selected) openScreen(i);
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}