import 'package:flutter/material.dart';

import 'status_badge.dart';

// Карточка растения в списке
class PlantCard extends StatelessWidget {
  final String name;
  final String species;
  final String lastWatered;
  final bool isWatered;
  final VoidCallback? onTap;

  const PlantCard({
    super.key,
    required this.name,
    required this.species,
    required this.lastWatered,
    required this.isWatered,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.local_florist, color: colors.onPrimaryContainer),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(species),
              const SizedBox(height: 4),
              Text('Полито: $lastWatered'),
            ],
          ),
        ),
        trailing: StatusBadge(isWatered: isWatered),
      ),
    );
  }
}