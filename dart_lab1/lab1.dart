mixin Loggable {
  void log(String msg) {
    print('[$runtimeType] $msg');
  }
}

class CartService with Loggable {
  void addItem(String item) {
    log('Товар добавлен: $item');
  }
}

class AuthService with Loggable {
  void login(String username) {
    log('Пользователь вошёл: $username');
  }
}

void main() {
  final cart = CartService();
  final auth = AuthService();

  cart.addItem('Молоко');
  auth.login('student01');
}