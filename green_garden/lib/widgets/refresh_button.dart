import 'package:flutter/material.dart';

// «Обновить» в AppBar: заново запрашивает данные у хранилища.
// Нужна и для демонстрации аварии: включили сбой в профиле →
// «Обновить» → спиннер → ErrorView с «Повторить».
class RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const RefreshButton({
    super.key,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Обновить',
      onPressed: isLoading ? null : onRefresh, // во время загрузки неактивна
    );
  }
}
