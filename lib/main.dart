import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app_controller.dart';
import 'app/hans_app.dart';
import 'data/note_repository.dart';
import 'data/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows and Linux have no native sqflite plugin, so the FFI
  // implementation backed by sqlite3 is used instead.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final preferences = await PreferencesStore.load();
  final controller = AppController(
    preferences: preferences,
    repository: NoteRepository(),
  );
  await controller.initialize();

  runApp(HansApp(controller: controller));
}
