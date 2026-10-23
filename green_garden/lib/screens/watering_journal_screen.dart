import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plants_model.dart';
import '../models/water_plant.dart';
import '../models/watering_log_model.dart';
import '../utils/dates.dart';
import '../widgets/error_view.dart';
import '../widgets/section_title.dart';

class WateringJournalScreen extends StatelessWidget {
  const WateringJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch в build: новая запись появится в списке сама
    final model = context.watch<WateringLogModel>();
    final plants = context.watch<PlantsModel>();

    // Три состояния списка записей
    final List<Widget> entries;
    if (model.isLoading) {
      entries = const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (model.error != null) {
      entries = [
        ErrorView(
          message: model.error!,
          onRetry: () => context.read<WateringLogModel>().load(),
        ),
      ];
    } else if (model.logs.isEmpty) {
      entries = const [Center(child: Text('Записей пока нет'))];
    } else {
      entries = [
        for (final log in model.logs)
          // Свайп влево удаляет запись. Ключ — id из данных, не UniqueKey.
          Dismissible(
            key: ValueKey(log.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            // Удаляем через модель; если хранилище вернуло ошибку —
            // запись остаётся на месте, показываем SnackBar.
            confirmDismiss: (_) async {
              final error =
                  await context.read<WateringLogModel>().remove(log.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(error)));
              }
              return error == null;
            },
            child: _LogItem(
              plant: plants.byId(log.plantId)?.name ?? 'Растение удалено',
              dateTime: formatDateTime(log.date),
              note: log.note,
            ),
          ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал полива'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _WaterForm(),
          const SectionTitle('Последние записи'),
          ...entries,
        ],
      ),
    );
  }
}

// Форма «Отметить полив». Выбранное растение и текст заметки —
// эфемерное состояние формы, поэтому StatefulWidget + setState.
class _WaterForm extends StatefulWidget {
  const _WaterForm();

  @override
  State<_WaterForm> createState() => _WaterFormState();
}

class _WaterFormState extends State<_WaterForm> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  int? _plantId;
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final error = await waterPlant(
      plants: context.read<PlantsModel>(),
      logs: context.read<WateringLogModel>(),
      plantId: _plantId!,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return; // экран мог закрыться, пока «запрос» летел
    setState(() => _saving = false);

    if (error != null) {
      // данные остаются в полях — можно повторить
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _noteCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Полив записан в журнал')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantsModel>().plants;
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Отметить полив',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _plantId,
                decoration: const InputDecoration(
                  labelText: 'Растение',
                  prefixIcon: Icon(Icons.local_florist_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in plants)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (value) => setState(() => _plantId = value),
                validator: (value) =>
                    value == null ? 'Выберите растение' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Дата',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(formatDate(now)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Время',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(formatTime(now)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Заметка',
                  hintText: 'Например: земля была сухая',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _saving ? null : _save, // null — кнопка неактивна
                icon: const Icon(Icons.water_drop),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_saving ? 'Сохранение…' : 'Отметить полив'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String plant;
  final String dateTime;
  final String note;

  const _LogItem({
    required this.plant,
    required this.dateTime,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.water_drop, color: colors.onPrimaryContainer),
        ),
        title: Text(
          plant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(note.isEmpty ? dateTime : '$dateTime\n$note'),
        isThreeLine: note.isNotEmpty,
      ),
    );
  }
}
