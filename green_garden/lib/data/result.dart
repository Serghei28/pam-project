// Вердикт операции с данными (лекция C8).
// Ожидаемый отказ (нет сети, нет такого id) — это значение, а не исключение.
// sealed: switch по Result обязан обработать обе ветки — компилятор
// не даст забыть про ошибку.
sealed class Result<T> {
  const Result();
}

// Успех: внутри — полученное значение
class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

// Ошибка: внутри — сообщение, которое можно показать на экране
class Err<T> extends Result<T> {
  const Err(this.msg);
  final String msg;
}
