import 'dart:io';

import 'package:flutter/material.dart';

import '../data/export_service.dart';
import '../data/note_repository.dart';
import '../data/preferences_store.dart';
import '../models/note.dart';

/// Single source of truth for the UI: notes, theme choice and export state.
class AppController extends ChangeNotifier {
  AppController({
    required this.preferences,
    required this.repository,
  });

  final PreferencesStore preferences;
  final NoteRepository repository;

  ThemeMode _themeMode = ThemeMode.system;
  List<Note> _notes = const <Note>[];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _lastExportPath;

  ThemeMode get themeMode => _themeMode;
  List<Note> get notes => List<Note>.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get lastExportPath => _lastExportPath;

  List<Note> get pinnedNotes =>
      _notes.where((note) => note.pinned).toList(growable: false);

  List<Note> get recentNotes => _notes.take(3).toList(growable: false);

  int get pinnedCount => _notes.where((note) => note.pinned).length;

  Future<void> initialize() async {
    _themeMode = preferences.themeMode;
    _lastExportPath = preferences.lastExportPath;
    await _reloadNotes();
    _isLoading = false;
    notifyListeners();
  }

  Note? noteById(int id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await preferences.setThemeMode(mode);
  }

  Future<void> saveNote({
    Note? existing,
    required String title,
    required String body,
    required bool pinned,
  }) async {
    final now = DateTime.now();
    if (existing?.id != null) {
      await repository.update(
        existing!.copyWith(
          title: title.trim(),
          body: body.trim(),
          pinned: pinned,
          updatedAt: now,
        ),
      );
    } else {
      await repository.insert(
        Note(
          title: title.trim(),
          body: body.trim(),
          pinned: pinned,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await _reloadNotes();
  }

  Future<void> togglePin(Note note) async {
    await repository.update(
      note.copyWith(pinned: !note.pinned, updatedAt: DateTime.now()),
    );
    await _reloadNotes();
  }

  Future<void> deleteNote(Note note) async {
    final id = note.id;
    if (id == null) return;
    await repository.delete(id);
    await _reloadNotes();
  }

  Future<File> exportNotes() async {
    if (_isExporting) {
      throw StateError('An export is already running');
    }
    _isExporting = true;
    notifyListeners();
    try {
      final file = await exportNotesAsJson(_notes);
      _lastExportPath = file.path;
      await preferences.setLastExportPath(file.path);
      return file;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> _reloadNotes() async {
    _notes = await repository.all();
    notifyListeners();
  }
}
