import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Напоминания'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('Предстоящие'),
          _ReminderItem(
            plant: 'Орхидея',
            type: 'Полить',
            dueDate: 'Просрочено: 6 окт. 2026',
            isDone: false,
            isOverdue: true,
          ),
          _ReminderItem(
            plant: 'Фикус Бенджамина',
            type: 'Полить',
            dueDate: 'Сегодня, 8 окт. 2026',
            isDone: false,
            isOverdue: false,
          ),
          _ReminderItem(
            plant: 'Монстера',
            type: 'Полить',
            dueDate: '14 окт. 2026',
            isDone: false,
            isOverdue: false,
          ),
          _ReminderItem(
            plant: 'Монстера',
            type: 'Протереть листья',
            dueDate: '20 окт. 2026',
            isDone: false,
            isOverdue: false,
          ),

          _SectionTitle('Выполненные'),
          _ReminderItem(
            plant: 'Алоэ',
            type: 'Полить',
            dueDate: '5 окт. 2026',
            isDone: true,
            isOverdue: false,
          ),
          _ReminderItem(
            plant: 'Замиокулькас',
            type: 'Подкормка',
            dueDate: '4 окт. 2026',
            isDone: true,
            isOverdue: false,
          ),
        ],
      ),
    );
  }
}

// Заголовок раздела
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// Одно напоминание в списке
class _ReminderItem extends StatelessWidget {
  final String plant;
  final String type;
  final String dueDate;
  final bool isDone;
  final bool isOverdue;

  const _ReminderItem({
    required this.plant,
    required this.type,
    required this.dueDate,
    required this.isDone,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? colors.primary : colors.outline,
        ),
        title: Text(
          '$type: $plant',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          dueDate,
          style: TextStyle(color: isOverdue ? colors.error : null),
        ),
        trailing: Icon(
          type == 'Полить' ? Icons.water_drop_outlined : Icons.eco_outlined,
        ),
      ),
    );
  }
}