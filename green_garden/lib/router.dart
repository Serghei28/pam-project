import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/plant_card_screen.dart';
import 'screens/plant_form_screen.dart';
import 'screens/plants_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/watering_journal_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
            return const PlantCardScreen();
          },
        ),
      ],
    ),
    GoRoute(
      path: '/journal',
      builder: (context, state) => const WateringJournalScreen(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RemindersScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);