// Доменная модель записи журнала полива (переживёт L5).
class WateringLog {
  final int id;
  final int plantId; // какое растение полили
  final DateTime date;
  final String note;

  const WateringLog({
    required this.id,
    required this.plantId,
    required this.date,
    this.note = '',
  });

  // Граница JSON (L5): на проводе UTC, в приложении — местное время
  factory WateringLog.fromJson(Map<String, dynamic> j) => WateringLog(
    id: j['id'] as int,
    plantId: j['plantId'] as int,
    date: DateTime.parse(j['date'] as String).toLocal(),
    note: j['note'] as String? ?? '',
  );

  // Без id — идентичность даёт сервер
  Map<String, dynamic> toJson() => {
    'plantId': plantId,
    'date': date.toUtc().toIso8601String(),
    'note': note,
  };

  WateringLog copyWith({int? id}) {
    return WateringLog(
      id: id ?? this.id,
      plantId: plantId,
      date: date,
      note: note,
    );
  }
}
