import 'package:flutter/material.dart';

import '../database/note_database.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/search_field.dart';
import 'note_form_screen.dart';

/// Cách sắp xếp danh sách ghi chú.
enum NoteSort { newest, title, color }

extension NoteSortLabel on NoteSort {
  String get label {
    switch (this) {
      case NoteSort.newest:
        return 'Mới nhất';
      case NoteSort.title:
        return 'Tiêu đề A-Z';
      case NoteSort.color:
        return 'Theo màu';
    }
  }
}

/// Màn hình chính: tìm kiếm + bộ lọc + danh sách ghi chú + nút thêm mới.
class HomeScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteDatabase _db = NoteDatabase.instance;
  final TextEditingController _searchController = TextEditingController();

  List<NoteModel> _notes = [];
  String _query = '';
  NoteSort _sort = NoteSort.newest;
  bool _onlyPinned = false;
  bool _onlyLocked = false;
  String? _activeTag;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Tải danh sách ghi chú từ database (gọi lại sau mỗi thao tác thêm/sửa/xóa).
  Future<void> _loadNotes() async {
    final notes = await _db.getAllNotes();
    if (!mounted) {
      return;
    }
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  /// Tất cả tag đang có trong danh sách (không trùng lặp, sắp xếp A-Z).
  List<String> get _allTags {
    final tags = _notes.expand((note) => note.tags).toSet().toList()..sort();
    return tags;
  }

  /// Áp dụng tìm kiếm + bộ lọc + sắp xếp lên danh sách ghi chú.
  List<NoteModel> get _visibleNotes {
    final q = _query.trim().toLowerCase();
    final result = _notes.where((note) {
      final matchesQuery = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.content.toLowerCase().contains(q) ||
          note.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchesPinned = !_onlyPinned || note.isFavorite;
      final matchesLocked = !_onlyLocked || note.isLocked;
      final matchesTag = _activeTag == null || note.tags.contains(_activeTag);
      return matchesQuery &&
          matchesPinned &&
          matchesLocked &&
          matchesTag;
    }).toList();

    switch (_sort) {
      case NoteSort.newest:
        // Ghim luôn nổi lên đầu, còn lại mới nhất trước
        result.sort((a, b) {
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          return b.updatedAt.compareTo(a.updatedAt);
        });
      case NoteSort.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case NoteSort.color:
        result.sort((a, b) => a.accentColor.toARGB32().compareTo(b.accentColor.toARGB32()));
    }
    return result;
  }

  /// Mở màn hình thêm mới / chỉnh sửa, sau khi lưu thì tải lại danh sách.
  Future<void> _openForm({NoteModel? note}) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: note)),
    );
    if (saved == true) {
      await _loadNotes();
    }
  }

  /// Nhấn vào ghi chú: nếu có PIN thì hỏi PIN trước, đúng mới mở form sửa.
  Future<void> _openNote(NoteModel note) async {
    if (note.isLocked) {
      final correct = await showPinDialog(context, note.password!) ?? false;
      if (!correct || !mounted) {
        return;
      }
    }
    await _openForm(note: note);
  }

  /// Bật/tắt ghim ghi chú ngay trên danh sách.
  Future<void> _toggleFavorite(NoteModel note) async {
    await _db.toggleFavorite(note);
    await _loadNotes();
  }

  /// Xóa ghi chú + hiện SnackBar cho phép hoàn tác trong vài giây.
  Future<void> _deleteNote(NoteModel note) async {
    try {
      await _db.deleteNote(note.id!);
      await _loadNotes();
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${note.title}"'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            // Chèn lại ghi chú (id cũ không cần giữ, SQLite tự sinh id mới)
            onPressed: () async {
              await _db.insertNote(note.copyWith(id: null));
              await _loadNotes();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra. Vui lòng thử lại.')),
      );
    }
  }

  /// Xóa khi nhấn giữ lâu (dùng chung hộp thoại xác nhận với vuốt).
  Future<void> _confirmDelete(NoteModel note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Xóa ghi chú?'),
          content: Text(
            'Bạn có chắc chắn muốn xóa ghi chú "${note.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteNote(note);
    }
  }

  /// Hàng chip lọc: tất cả / ghim / khóa / từng tag.
  Widget _filterBar() {
    final theme = Theme.of(context);
    final tags = _allTags;
    if (tags.isEmpty && !_onlyPinned && !_onlyLocked && _activeTag == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          FilterChip(
            label: const Text('Tất cả'),
            selected: !_onlyPinned && !_onlyLocked && _activeTag == null,
            onSelected: (_) => setState(() {
              _onlyPinned = false;
              _onlyLocked = false;
              _activeTag = null;
            }),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.push_pin, size: 16),
            label: const Text('Ghim'),
            selected: _onlyPinned,
            onSelected: (value) => setState(() => _onlyPinned = value),
          ),
          const SizedBox(width: 8),
          FilterChip(
            avatar: const Icon(Icons.lock, size: 16),
            label: const Text('Khóa'),
            selected: _onlyLocked,
            onSelected: (value) => setState(() => _onlyLocked = value),
          ),
          for (final tag in tags) ...[
            const SizedBox(width: 8),
            FilterChip(
              avatar: const Icon(Icons.sell, size: 16),
              label: Text(tag),
              labelStyle: const TextStyle(fontSize: 13),
              selected: _activeTag == tag,
              selectedColor: theme.colorScheme.primaryContainer,
              onSelected: (selected) =>
                  setState(() => _activeTag = selected ? tag : null),
            ),
          ],
        ],
      ),
    );
  }

  /// Màn hình trống khi không có ghi chú nào khớp bộ lọc.
  Widget _emptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_alt_off : Icons.note_add_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered ? 'Không có ghi chú khớp bộ lọc' : 'Chưa có ghi chú nào',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Thử tìm từ khóa khác hoặc bỏ bớt bộ lọc'
                : 'Nhấn nút Thêm ghi chú để bắt đầu',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = _visibleNotes;
    final isFiltered = _query.isNotEmpty ||
        _onlyPinned ||
        _onlyLocked ||
        _activeTag != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú cá nhân',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Menu chọn cách sắp xếp
          PopupMenuButton<NoteSort>(
            tooltip: 'Sắp xếp',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => [
              for (final sort in NoteSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Đổi giao diện sáng/tối',
            onPressed: () => widget.onToggleTheme(
              theme.brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          _filterBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tổng ${_notes.length} ghi chú'
                '${_notes.isEmpty ? '' : ' • ${notes.length} hiển thị'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? _emptyState(isFiltered)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return NoteCard(
                            note: note,
                            onTap: () => _openNote(note),
                            onLongPress: () => _confirmDelete(note),
                            onToggleFavorite: () => _toggleFavorite(note),
                            onDismissed: () => _deleteNote(note),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi chú'),
      ),
    );
  }
}