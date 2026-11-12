// Общие «повадки сети» для всех mock-хранилищ: задержка ответа
// и переключаемый сбой. Леса L4 — на L5 исчезнут вместе с mock-ами.

const mockLatency = Duration(milliseconds: 800);
const mockNetworkError = 'Сервер не отвечает — повторите попытку';

// Первый id, который mock выдаёт новым объектам (больше любого id из seed-а)
const mockFirstNewId = 1000;

mixin MockNetwork {
  // Сбой сети: включён → любой вызов возвращает Err
  bool simulateError = false;

  // Задержка ответа; в unit-тестах ставят Duration.zero
  Duration latency = mockLatency;

  // Общий пролог каждого метода: задержка + проверка сбоя.
  // Возвращает текст ошибки или null, если «сеть» ответила.
  Future<String?> simulateNetwork() async {
    await Future.delayed(latency); // сеть не отвечает мгновенно
    return simulateError ? mockNetworkError : null;
  }
}
