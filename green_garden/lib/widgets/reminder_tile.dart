import 'package:flutter/material.dart';

import '../data/reminder.dart';

// Одна строка напоминания: полив или уход.
// Используется на экране напоминаний и в карточке растения.
class ReminderTile extends StatelessWidget {
  final String title;
  final String dueText;
  final bool isDone;
  final bool isOverdue;
  final IconData icon;
  final VoidCallback? onTap;

  const ReminderTile({
    super.key,
    required this.title,
    required this.dueText,
    required this.icon,
    this.isDone = false,
    this.isOverdue = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? colors.primary : colors.outline,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          dueText,
          style: TextStyle(color: isOverdue ? colors.error : null),
        ),
        trailing: Icon(icon),
      ),
    );
  }
}

// Иконка для вида ухода (это оформление, поэтому оно здесь, а не в данных)
IconData reminderIcon(ReminderType type) {
  switch (type) {
    case ReminderType.wipeLeaves:
      return Icons.cleaning_services_outlined;
    case ReminderType.fertilize:
      return Icons.science_outlined;
    case ReminderType.spray:
      return Icons.shower_outlined;
    case ReminderType.repot:
      return Icons.yard_outlined;
  }
}
