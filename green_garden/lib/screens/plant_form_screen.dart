import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/plant.dart';
import '../models/plants_model.dart';

class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key});

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController();
  bool _saving = false; // эфемерное состояние формы → setState

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  // Валидный submit ПИШЕТ через модель (а модель — через repository),
  // затем уходит. Валидация из L3 не тронута.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = Plant(
      id: 0, // временный id — настоящий выдаст хранилище (на L5: сервер)
      name: _nameCtrl.text.trim(),
      species: _speciesCtrl.text.trim(),
      wateringIntervalDays: int.parse(_intervalCtrl.text),
      lastWateredAt: DateTime.now(), // новое растение считаем политым сегодня
    );

    setState(() => _saving = true);
    final error = await context.read<PlantsModel>().add(draft);
    if (!mounted) return; // экран мог закрыться, пока «запрос» летел
    setState(() => _saving = false);

    if (error != null) {
      // данные остаются в полях — можно повторить
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сохранено: ${draft.name}')),
    );
    context.pop(); // список позади УЖЕ вырос — без лишних вызовов
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое растение'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            
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
                
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Выбрать фото'),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Монстера',
                prefixIcon: Icon(Icons.local_florist_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Название обязательно'
                  : null, 
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _speciesCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Вид',
                hintText: 'Например: Monstera deliciosa',
                prefixIcon: Icon(Icons.eco_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _intervalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Интервал полива',
                hintText: 'Например: 7',
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'дн.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final days = int.tryParse(value ?? '');
                if (days == null) return 'Введите число дней';
                if (days < 1) return 'Интервал должен быть не меньше 1 дня';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save, // null — кнопка неактивна
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}