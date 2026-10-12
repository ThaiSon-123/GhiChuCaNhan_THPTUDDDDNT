import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/note_database.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart' show kNoteColors;

/// Màn hình thêm mới / chỉnh sửa ghi chú.
/// note = null → thêm mới, khác null → chỉnh sửa.
class NoteFormScreen extends StatefulWidget {
  final NoteModel? note;

  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _pinController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLocked = false;
  bool _isFavorite = false;
  int? _colorValue;
  bool _isSaving = false;

  /// Các tag đang có trong toàn bộ ghi chú (gợi ý khi nhập).
  List<String> _existingTags = [];

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _isLocked = note.isLocked;
      _pinController.text = note.password ?? '';
      _isFavorite = note.isFavorite;
      _colorValue = note.colorValue;
      _tagsController.text = note.tags.join(', ');
    }
    _loadExistingTags();
  }

  /// Nạp các tag hiện có để hiển thị gợi ý.
  Future<void> _loadExistingTags() async {
    final notes = await NoteDatabase.instance.getAllNotes();
    if (!mounted) {
      return;
    }
    setState(() {
      _existingTags = notes
          .expand((note) => note.tags)
          .toSet()
          .toList()
        ..sort();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pinController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// Lưu ghi chú vào database, sau đó quay lại màn hình chính.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLocked && _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã PIN cho ghi chú')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = NoteDatabase.instance;
    final now = DateTime.now();

    try {
      final note = NoteModel(
        id: _isEditing ? widget.note!.id : null,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        password: _isLocked ? _pinController.text : null,
        createdAt: _isEditing ? widget.note!.createdAt : now,
        updatedAt: now,
        isFavorite: _isFavorite,
        colorValue: _colorValue,
        tags: NoteModel.parseTags(_tagsController.text),
      );

      if (_isEditing) {
        await db.updateNote(note);
      } else {
        await db.insertNote(note);
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa ghi chú' : 'Thêm ghi chú'),
        actions: [
          // Nút ghim nhanh ngay trên thanh tiêu đề
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isFavorite ? Colors.orange.shade700 : null,
            ),
            tooltip: 'Ghim ghi chú',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Lưu',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Vui lòng nhập tiêu đề'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                minLines: 5,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Vui lòng nhập nội dung'
                        : null,
              ),
              const SizedBox(height: 16),
              // Nhập thẻ tag, phân cách bằng dấu phẩy
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Thẻ tag (cách nhau bằng dấu phẩy)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell),
                ),
              ),
              if (_existingTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in _existingTags)
                      ActionChip(
                        label: Text(tag),
                        avatar: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          final current = NoteModel.parseTags(
                              _tagsController.text);
                          if (!current.contains(tag)) {
                            setState(() {
                              _tagsController.text = [
                                ...current,
                                tag
                              ].join(', ');
                            });
                          }
                        },
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // Chọn dải màu pastel cho ghi chú
              Text('Màu ghi chú', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final colorValue in kNoteColors)
                    GestureDetector(
                      onTap: () => setState(() {
                        // Bấm lại màu đang chọn = bỏ chọn, dùng màu mặc định
                        _colorValue =
                            _colorValue == colorValue ? null : colorValue;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == colorValue
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: _colorValue == colorValue
                              ? [
                                  BoxShadow(
                                    color: Color(colorValue).withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: _colorValue == colorValue
                            ? const Icon(Icons.check,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Khóa ghi chú này bằng mã PIN'),
                        secondary: const Icon(Icons.lock_outline),
                        value: _isLocked,
                        onChanged: (value) =>
                            setState(() => _isLocked = value),
                      ),
                      if (_isLocked)
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Mã PIN',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.pin),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Lưu'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}