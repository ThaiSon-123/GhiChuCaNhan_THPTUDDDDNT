import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';

/// Lớp truy cập database SQLite cho ghi chú (singleton).
class NoteDatabase {
  NoteDatabase._();
  static final NoteDatabase instance = NoteDatabase._();

  static const _dbName = 'notes.db';
  static const _table = 'notes';

  Database? _db;

  /// Lấy (và khởi tạo lần đầu) database.
  Future<Database> get database async {
    return _db ??= await _initDatabase();
  }

  /// Mở database, tạo bảng notes nếu chưa có, nâng cấp nếu có phiên bản cũ.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            password TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            color_value INTEGER,
            tags TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
      // Nâng cấp schema qua từng phiên bản (giữ nguyên dữ liệu cũ)
      onUpgrade: (db, oldVersion, newVersion) async {
        // Lấy danh sách cột hiện có, chỉ thêm cột chưa tồn tại
        final columns = await db.rawQuery('PRAGMA table_info($_table)');
        final existing =
            columns.map((col) => col['name'] as String).toSet();

        if (oldVersion < 2) {
          if (!existing.contains('is_favorite')) {
            await db.execute(
              'ALTER TABLE $_table ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (!existing.contains('color_value')) {
            await db.execute(
              'ALTER TABLE $_table ADD COLUMN color_value INTEGER',
            );
          }
        }
        if (oldVersion < 3 && !existing.contains('tags')) {
          await db.execute(
            "ALTER TABLE $_table ADD COLUMN tags TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }

  /// Lấy tất cả ghi chú: ghi chú ghim trước, sau đó mới cập nhật gần nhất.
  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final rows = await db.query(
      _table,
      orderBy: 'is_favorite DESC, updated_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  /// Thêm ghi chú mới, trả về id vừa tạo.
  Future<int> insertNote(NoteModel note) async {
    final db = await database;
    return db.insert(_table, note.toMap());
  }

  /// Cập nhật ghi chú (updated_at được set lại ở tầng UI).
  Future<void> updateNote(NoteModel note) async {
    final db = await database;
    await db.update(
      _table,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// Bật/tắt ghim một ghi chú mà không cần mở form sửa.
  Future<void> toggleFavorite(NoteModel note) async {
    await updateNote(note.copyWith(isFavorite: !note.isFavorite));
  }

  /// Xóa ghi chú theo id.
  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}