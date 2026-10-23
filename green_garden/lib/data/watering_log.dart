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

  WateringLog copyWith({int? id}) {
    return WateringLog(
      id: id ?? this.id,
      plantId: plantId,
      date: date,
      note: note,
    );
  }
}
