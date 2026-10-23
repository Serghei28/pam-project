import 'package:flutter/material.dart';

// Обёртка для асинхронного действия (полив, удаление, отметка «выполнено»).
// Пока действие выполняется, повторные нажатия игнорируются:
// builder получает busy == true и run == null (кнопка неактивна).
// «Идёт операция» — эфемерное состояние одного виджета → setState.
class AsyncAction extends StatefulWidget {
  final Future<void> Function() action;
  final Widget Function(BuildContext context, bool busy, VoidCallback? run)
      builder;

  const AsyncAction({super.key, required this.action, required this.builder});

  @override
  State<AsyncAction> createState() => _AsyncActionState();
}

class _AsyncActionState extends State<AsyncAction> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.action();
    } finally {
      // виджет мог исчезнуть, пока шла операция (например, растение удалено)
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _busy, _busy ? null : _run);
}

// Маленький спиннер для кнопок и строк списка
class SmallSpinner extends StatelessWidget {
  const SmallSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
