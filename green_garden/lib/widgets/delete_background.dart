import 'package:flutter/material.dart';

// Красный фон с корзиной, который виден под элементом при свайпе
class DeleteBackground extends StatelessWidget {
  final double bottomMargin;

  const DeleteBackground({super.key, this.bottomMargin = 8});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
    );
  }
}
