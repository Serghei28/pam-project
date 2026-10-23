import 'plants_model.dart';
import 'reminder_model.dart';

// «Дел по уходу» = растения, которые пора полить + невыполненные напоминания.
// Одна формула для статистики в профиле и бейджа на вкладке «Напоминания»,
// чтобы два места не показывали разные числа.
int careTaskCount(PlantsModel plants, ReminderModel reminders) =>
    plants.dueCount + reminders.pendingCount;
