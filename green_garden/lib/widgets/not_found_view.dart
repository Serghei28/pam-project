import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// «Не найдено»: сообщение + кнопка возврата к списку растений.
// Используется в карточке (нет растения с таким id) и в router-е
// (адреса нет вообще).
class NotFoundView extends StatelessWidget {
  final String message;

  const NotFoundView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: colors.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/plants'),
              child: const Text('К списку растений'),
            ),
          ],
        ),
      ),
    );
  }
}
