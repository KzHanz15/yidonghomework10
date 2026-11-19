import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../models/note.dart';
import '../screens/note_detail_screen.dart';
import '../screens/note_editor_screen.dart';

Future<void> openNoteDetail(
  BuildContext context,
  AppController controller,
  Note note,
) {
  final id = note.id;
  if (id == null) return Future<void>.value();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteDetailScreen(controller: controller, noteId: id),
    ),
  );
}

Future<void> openNoteEditor(
  BuildContext context,
  AppController controller, {
  Note? note,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => NoteEditorScreen(controller: controller, existing: note),
    ),
  );
}
