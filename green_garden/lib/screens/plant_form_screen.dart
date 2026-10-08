import 'package:flutter/material.dart';

class PlantFormScreen extends StatelessWidget {
  const PlantFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое растение'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Блок выбора фото (пока заглушка)
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo_outlined,
                  size: 56,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Фото растения',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Пока экран статический: кнопка ничего не делает
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Выбрать фото'),
          ),
          const SizedBox(height: 24),

          const TextField(
            decoration: InputDecoration(
              labelText: 'Название',
              hintText: 'Например: Монстера',
              prefixIcon: Icon(Icons.local_florist_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          const TextField(
            decoration: InputDecoration(
              labelText: 'Вид',
              hintText: 'Например: Monstera deliciosa',
              prefixIcon: Icon(Icons.eco_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          const TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Интервал полива',
              hintText: 'Например: 7',
              prefixIcon: Icon(Icons.schedule),
              suffixText: 'дн.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: () {
              // Пока экран статический: кнопка ничего не делает
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Сохранить'),
            ),
          ),
        ],
      ),
    );
  }
}