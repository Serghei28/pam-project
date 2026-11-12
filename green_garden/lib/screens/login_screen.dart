import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/plants_model.dart';
import '../models/reminder_model.dart';
import '../models/watering_log_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLogin = true;

  // Запрос летит — кнопка погашена: двойной submit = классический сетевой bug.
  // Эфемерное состояние экрана → setState.
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _formKey.currentState?.reset();
  }

  // Валидный submit бьёт по серверу: вердикт → навигация или SnackBar
  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута

    final auth = context.read<AuthApi>();
    setState(() => _busy = true);
    final result = _isLogin
        ? await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text)
        : await auth.register(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
          );
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);

    switch (result) {
      case Ok():
        // Модели живут в корне и переживают logout: перезагружаем их под
        // новым token-ом — иначе после смены аккаунта видны чужие данные,
        // а после «Сессия истекла» — старый экран ошибки.
        // search: '' — фильтр поиска от прошлого входа не переносится
        context.read<PlantsModel>().load(search: '');
        context.read<WateringLogModel>().load();
        context.read<ReminderModel>().load();
        context.go('/plants'); // token сохранён — входим в список
      case Err(:final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.local_florist, size: 80, color: colors.primary),
                    const SizedBox(height: 12),
                    Text(
                      'GreenGarden',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin
                          ? 'Войдите в свой аккаунт'
                          : 'Создайте новый аккаунт',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Имя',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Имя обязательно'
                                : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Введите email';
                        if (!email.contains('@')) {
                          return 'Email должен содержать @';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Пароль',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) {
                          return 'Пароль должен быть не короче 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _busy ? null : _toggleMode,
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}