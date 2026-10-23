// Календарная арифметика: считаем ДНИ, а не 24-часовые отрезки.
// Чистый Dart — используют и доменные модели (data/), и экраны.

// Сколько календарных дней от from до to (положительно, если to позже).
// Считаем через DateTime.utc: в UTC нет перехода на летнее/зимнее время,
// поэтому каждый день — ровно 24 часа и inDays не ошибается на единицу.
// (В местном времени ночь перевода часов длится 23 или 25 часов.)
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

// Дата через days календарных дней. DateTime(y, m, d + n) сам переносит
// месяц и год (31 янв + 1 → 1 февр) и не зависит от перевода часов.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);
