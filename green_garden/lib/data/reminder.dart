// Виды ухода, о которых можно напомнить.
// Полив сюда не входит: его срок вычисляется из интервала полива растения.
enum ReminderType {
  wipeLeaves('Протереть листья'),
  fertilize('Подкормка'),
  spray('Опрыскать'),
  repot('Пересадка');

  const ReminderType(this.label);
  final String label;
}

// Доменная модель напоминания (переживёт L5).
class Reminder {
  final int id;
  final int plantId;
  final ReminderType type;
  final DateTime dueDate;
  final bool isDone;

  const Reminder({
    required this.id,
    required this.plantId,
    required this.type,
    required this.dueDate,
    this.isDone = false,
  });

  // Просрочено: не выполнено, а срок уже прошёл (раньше сегодняшнего дня)
  bool isOverdueOn(DateTime day) =>
      !isDone && _dateOnly(dueDate).isBefore(_dateOnly(day));

  bool get isOverdue => isOverdueOn(DateTime.now());

  Reminder copyWith({
    int? id,
    int? plantId,
    ReminderType? type,
    DateTime? dueDate,
    bool? isDone,
  }) {
    return Reminder(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
