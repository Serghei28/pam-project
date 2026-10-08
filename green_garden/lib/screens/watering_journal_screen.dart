import 'package:flutter/material.dart';

class WateringJournalScreen extends StatelessWidget {
  const WateringJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал полива'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Форма отметки полива
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Отметить полив',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    initialValue: 'Монстера',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Растение',
                      prefixIcon: Icon(Icons.local_florist_outlined),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: '8 окт. 2026',
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Дата',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: '09:00',
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Время',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Заметка',
                      hintText: 'Например: земля была сухая',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: () {
                      // Пока экран статический: кнопка ничего не делает
                    },
                    icon: const Icon(Icons.water_drop),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Отметить полив'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // История записей
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              'Последние записи',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const _LogItem(
            plant: 'Монстера',
            dateTime: '7 окт. 2026, 09:00',
            note: 'Земля была сухая',
          ),
          const _LogItem(
            plant: 'Алоэ',
            dateTime: '5 окт. 2026, 18:30',
            note: 'Немного, как обычно',
          ),
          const _LogItem(
            plant: 'Замиокулькас',
            dateTime: '4 окт. 2026, 10:15',
            note: 'Добавила подкормку',
          ),
          const _LogItem(
            plant: 'Фикус Бенджамина',
            dateTime: '2 окт. 2026, 08:45',
            note: 'Листья слегка опали',
          ),
        ],
      ),
    );
  }
}

// Одна запись в журнале
class _LogItem extends StatelessWidget {
  final String plant;
  final String dateTime;
  final String note;

  const _LogItem({
    required this.plant,
    required this.dateTime,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(Icons.water_drop, color: colors.onPrimaryContainer),
        ),
        title: Text(
          plant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$dateTime\n$note'),
        isThreeLine: true,
      ),
    );
  }
}