import 'package:flutter/material.dart';

// Метка статуса полива: «Полито» или «Пора поливать».
// Цвета берутся из темы, поэтому меняются вместе с seedColor.
class StatusBadge extends StatelessWidget {
  final bool isWatered;

  const StatusBadge({super.key, required this.isWatered});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final Color background =
        isWatered ? colors.primaryContainer : colors.errorContainer;
    final Color foreground =
        isWatered ? colors.onPrimaryContainer : colors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isWatered ? 'Полито' : 'Пора поливать',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}