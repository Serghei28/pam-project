import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'plants_screen.dart';
import 'plant_card_screen.dart';
import 'plant_form_screen.dart';

class ScreensMenu extends StatelessWidget {
  const ScreensMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экраны GreenGarden'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _MenuItem(
            title: 'Вход / регистрация',
            icon: Icons.login,
            screen: LoginScreen(),
          ),
          _MenuItem(
            title: 'Мои растения',
            icon: Icons.local_florist,
            screen: PlantsScreen(),
          ),
                    _MenuItem(
            title: 'Карточка растения',
            icon: Icons.eco,
            screen: PlantCardScreen(),
          ),
                    _MenuItem(
            title: 'Форма растения',
            icon: Icons.edit_note,
            screen: PlantFormScreen(),
          ),
          
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget screen;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}