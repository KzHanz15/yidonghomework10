import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

enum SearchScope { title, content, both }

/// SQLite persistence for notes.
///
/// Each note is one row, so the list can be filtered and sorted by the
/// database instead of shuffling everything in memory.
class NoteRepository {
  NoteRepository({this.databasePathOverride});

  static const String _table = 'notes';
  static const String _databaseName = 'hans_smart_notes.db';

  final String? databasePathOverride;
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    final path = databasePathOverride ?? await _resolveDatabasePath();
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL DEFAULT '',
            pinned INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<String> _resolveDatabasePath() async {
    final String directory;
    if (Platform.isAndroid || Platform.isIOS) {
      directory = await getDatabasesPath();
    } else {
      directory = (await getApplicationSupportDirectory()).path;
    }
    return p.join(directory, _databaseName);
  }

  Future<List<Note>> all() async {
    final rows = await (await _db).query(
      _table,
      orderBy: 'pinned DESC, updatedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> findById(int id) async {
    final rows = await (await _db).query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Note.fromMap(rows.first);
  }

  Future<List<Note>> search(String keyword, SearchScope scope) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const <Note>[];

    final like = '%$trimmed%';
    final String where;
    final List<Object?> args;
    switch (scope) {
      case SearchScope.title:
        where = 'title LIKE ?';
        args = [like];
      case SearchScope.content:
        where = 'body LIKE ?';
        args = [like];
      case SearchScope.both:
        where = '(title LIKE ? OR body LIKE ?)';
        args = [like, like];
    }

    final rows = await (await _db).query(
      _table,
      where: where,
      whereArgs: args,
      orderBy: 'pinned DESC, updatedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<int> insert(Note note) async {
    return (await _db).insert(_table, note.toMap());
  }

  Future<void> update(Note note) async {
    final id = note.id;
    if (id == null) {
      throw ArgumentError('Cannot update a note without an id');
    }
    await (await _db).update(
      _table,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    await (await _db).delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
