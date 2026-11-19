import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/note.dart';

/// Writes every note to a single JSON snapshot inside the app documents
/// directory, the same place a user would look for an exported backup.
Future<File> exportNotesAsJson(List<Note> notes) async {
  final directory = await getApplicationDocumentsDirectory();
  final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File(p.join(directory.path, 'hans_notes_$stamp.json'));

  final payload = <String, Object?>{
    'app': 'Hans Smart Local Notes',
    'version': '1.0.0',
    'exportedAt': DateTime.now().toIso8601String(),
    'count': notes.length,
    'notes': notes.map((note) => note.toJson()).toList(),
  };

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
  );
  return file;
}
