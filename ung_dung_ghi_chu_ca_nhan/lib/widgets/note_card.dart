import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note_model.dart';

/// Bảng màu pastel để gán cho từng ghi chú.
const List<int> kNoteColors = [
  0xFF7DD3C0, // teal
  0xFFF9A8D4, // pink
  0xFFC4B5FD, // violet
  0xFFFDE68A, // amber
  0xFF93C5FD, // blue
  0xFFA7F3D0, // mint
  0xFFFDBA74, // orange
  0xFFD8B4FE, // purple
];

/// Card hiển thị một ghi chú trong danh sách, có dải màu pastel bên trái.
class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onDismissed;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleFavorite,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = DateFormat('dd/MM/yyyy HH:mm').format(note.updatedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Dismissible(
        key: ValueKey(note.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        // Hộp thoại xác nhận trước khi xóa; trả về true => cho phép dismiss
        confirmDismiss: (_) async {
          final shouldDelete = await _confirmDelete(context);
          if (shouldDelete) {
            onDismissed?.call();
          }
          return false;
        },
        child: Card(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dải màu pastel phân biệt ghi chú
                  Container(width: 6, color: note.accentColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (note.isLocked)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child:
                                      Icon(Icons.lock, size: 17, color: Colors.amber),
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  note.isFavorite
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 20,
                                  color: note.isFavorite
                                      ? Colors.orange.shade700
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                tooltip: 'Ghim ghi chú',
                                onPressed: onToggleFavorite,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            note.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Hiển thị các thẻ tag (nếu có)
                          if (note.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final tag in note.tags)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: note.accentColor
                                          .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      // Nền chip luôn là màu pastel sáng → chữ đậm cho dễ đọc ở cả 2 chế độ
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        color: const Color(0xFF23262B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 4),
                          // Badge thời gian cập nhật + biểu tượng vuốt để xóa
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  timeText,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme
                                        .colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.swipe_left,
                                size: 16,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Hộp thoại xác nhận trước khi xóa vĩnh viễn.
  Future<bool> _confirmDelete(BuildContext context) async {
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
    // HomeScreen lắng nghe Dismissible hoàn tất và tự xóa
    return shouldDelete == true;
  }
}