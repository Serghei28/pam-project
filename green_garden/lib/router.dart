import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/plant_card_screen.dart';
import 'screens/plant_form_screen.dart';
import 'screens/plants_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/watering_journal_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/not_found_view.dart';

// Router строит main(): сначала он асинхронно читает token (C9),
// поэтому здесь late final, а не final с инициализатором.
late final GoRouter router;

// Маршруты L3 без изменений; меняется только то, куда ведёт заставка:
// есть token → сразу список, нет → экран входа.
GoRouter createRouter({required bool loggedIn}) => GoRouter(
  initialLocation: '/splash',
  // Неизвестный адрес (например, /abc в браузере) — понятный экран
  // вместо стандартной страницы ошибки go_router
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Страница не найдена')),
    body: const NotFoundView(message: 'Такой страницы в приложении нет'),
  ),
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) =>
          SplashScreen(next: loggedIn ? '/plants' : '/login'),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/plants',
              builder: (context, state) => const PlantsScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (context, state) => const PlantFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    // tryParse не падает на адресе вида /plants/abc:
                    // некорректный id → -1 → экран «Растение не найдено»
                    final id =
                        int.tryParse(state.pathParameters['id'] ?? '') ?? -1;
                    return PlantCardScreen(id: id);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (context, state) => const WateringJournalScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reminders',
              builder: (context, state) => const RemindersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);