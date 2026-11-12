import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/files_api.dart';
import '../data/plant.dart';
import '../data/result.dart';
import '../models/plants_model.dart';

// Ограничения полей формы
const _maxNameLength = 40;
const _maxSpeciesLength = 60;
const _minInterval = 1;
const _maxInterval = 365;

class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key});

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController();
  bool _saving = false; // эфемерное состояние формы → setState

  // Выбранное фото (L5): байты для превью и для POST /files при сохранении
  Uint8List? _photoBytes;
  String _photoName = '';
  String? _photoMime;

  Future<void> _pickPhoto() async {
    // Сжатие на стороне клиента: держимся далеко от лимита 5 МБ
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return; // пользователь передумал
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name;
      _photoMime = file.mimeType;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _speciesCtrl.dispose();
    _intervalCtrl.dispose();
    super.dispose();
  }

  // Валидный submit ПИШЕТ через модель (а модель — через repository),
  // затем уходит. Валидация из L3 не тронута.
  Future<void> _save() async {
    if (_saving) return; // уже сохраняем — повторный submit игнорируем
    if (!_formKey.currentState!.validate()) return;

    final plants = context.read<PlantsModel>();
    final files = context.read<FilesApi>();
    setState(() => _saving = true);

    // 1) Фото выбрано → сначала POST /files; растению достаётся его url
    String? photoUrl;
    final bytes = _photoBytes;
    if (bytes != null) {
      final uploaded = await files.upload(
        bytes,
        _photoName,
        mimeType: _photoMime,
      );
      if (!mounted) return;
      switch (uploaded) {
        case Ok(:final value):
          photoUrl = value;
        case Err(:final msg):
          setState(() => _saving = false);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
          return; // растение без обещанного фото не создаём
      }
    }

    // 2) Само растение
    final draft = Plant(
      id: 0, // временный id — настоящий выдаст хранилище (на L5: сервер)
      name: _nameCtrl.text.trim(),
      species: _speciesCtrl.text.trim(),
      wateringIntervalDays: int.parse(_intervalCtrl.text),
      lastWateredAt: DateTime.now(), // новое растение считаем политым сегодня
      photoUrl: photoUrl,
    );

    final error = await plants.add(draft);
    if (!mounted) return; // экран мог закрыться, пока «запрос» летел
    setState(() => _saving = false);

    if (error != null) {
      // данные остаются в полях — можно повторить
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сохранено: ${draft.name}')),
    );
    context.pop(); // список позади УЖЕ вырос — без лишних вызовов
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новое растение'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 180,
              clipBehavior: Clip.antiAlias, // скругление и для фото
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              // Превью выбранного фото — из памяти, до загрузки на сервер
              child: _photoBytes != null
                  ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 56,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Фото растения',
                          style: TextStyle(color: colors.onPrimaryContainer),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            // L5: фото уходит на backend (POST /files) при сохранении
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _photoBytes == null ? 'Выбрать фото' : 'Выбрать другое фото',
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              maxLength: _maxNameLength,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Монстера',
                prefixIcon: Icon(Icons.local_florist_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Название обязательно'
                  : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _speciesCtrl,
              textInputAction: TextInputAction.next,
              maxLength: _maxSpeciesLength,
              decoration: const InputDecoration(
                labelText: 'Вид (необязательно)',
                hintText: 'Например: Monstera deliciosa',
                prefixIcon: Icon(Icons.eco_outlined),
                border: OutlineInputBorder(),
              ),
              // Вид необязателен, но если указан — хотя бы 2 символа
              validator: (value) {
                final species = value?.trim() ?? '';
                if (species.isNotEmpty && species.length < 2) {
                  return 'Слишком короткое название вида';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _intervalCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 3, // больше 365 всё равно не пройдёт валидацию
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Интервал полива',
                hintText: 'От $_minInterval до $_maxInterval',
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'дн.',
                border: OutlineInputBorder(),
                counterText: '', // счётчик символов здесь не нужен
              ),
              validator: (value) {
                final days = int.tryParse(value ?? '');
                if (days == null) return 'Введите число дней';
                if (days < _minInterval) {
                  return 'Интервал должен быть не меньше $_minInterval дня';
                }
                if (days > _maxInterval) {
                  return 'Интервал должен быть не больше $_maxInterval дней';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save, // null — кнопка неактивна
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_saving ? 'Сохранение…' : 'Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}