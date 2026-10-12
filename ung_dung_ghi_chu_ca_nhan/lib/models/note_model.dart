import 'package:flutter/material.dart';

/// Model một ghi chú cá nhân.
class NoteModel {
  final int? id;
  final String title;
  final String content;

  /// Mã PIN khóa ghi chú. null/'' nghĩa là ghi chú không bị khóa.
  final String? password;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Ghi chú được ghim lên đầu danh sách.
  final bool isFavorite;

  /// Mã màu pastel (Color.value) của dải màu trên card, null = dùng màu mặc định.
  final int? colorValue;

  /// Danh sách thẻ tag của ghi chú.
  final List<String> tags;

  const NoteModel({
    this.id,
    required this.title,
    required this.content,
    this.password,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.colorValue,
    this.tags = const [],
  });

  /// Ghi chú có đang bị khóa bằng mã PIN không.
  bool get isLocked => password != null && password!.isNotEmpty;

  /// Màu dải pastel, có fallback về màu teal mặc định.
  Color get accentColor =>
      colorValue == null ? const Color(0xFF7DD3C0) : Color(colorValue!);

  /// Tạo NoteModel từ Map trả về từ SQLite.
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'] as String? ?? '';
    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      password: map['password'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      colorValue: map['color_value'] as int?,
      tags: parseTags(rawTags),
    );
  }

  /// Chuyển NoteModel thể Map để lưu vào SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'color_value': colorValue,
      'tags': tags.join(','),
    };
  }

  /// Tách chuỗi tag lưu trong DB thành List, bỏ khoảng trắng và tag rỗng.
  static List<String> parseTags(String raw) {
    return raw
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Tạo bản sao với vài trường được thay đổi (tiện cho update nhanh).
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? colorValue,
    List<String>? tags,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      colorValue: colorValue ?? this.colorValue,
      tags: tags ?? this.tags,
    );
  }
}