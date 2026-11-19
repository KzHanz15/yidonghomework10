import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hans_smart_local_notes/app/app_controller.dart';
import 'package:hans_smart_local_notes/app/hans_app.dart';
import 'package:hans_smart_local_notes/data/note_repository.dart';
import 'package:hans_smart_local_notes/data/preferences_store.dart';
import 'package:hans_smart_local_notes/models/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final List<NoteRepository> _repositories = <NoteRepository>[];

Future<AppController> buildController() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await PreferencesStore.load();
  final repository =
      NoteRepository(databasePathOverride: inMemoryDatabasePath);
  _repositories.add(repository);
  final controller = AppController(
    preferences: preferences,
    repository: repository,
  );
  await controller.initialize();
  return controller;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // sqflite keeps an in-memory database cached by path, so close every
  // connection to get a clean database for the next test.
  tearDown(() async {
    for (final repository in _repositories) {
      await repository.close();
    }
    _repositories.clear();
  });

  test('repository supports insert, pin ordering, search and delete',
      () async {
    final repository =
        NoteRepository(databasePathOverride: inMemoryDatabasePath);
    _repositories.add(repository);
    final now = DateTime.now();

    final firstId = await repository.insert(
      Note(
        title: 'Grocery list',
        body: 'Milk and bread',
        pinned: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.insert(
      Note(
        title: 'Flutter notes',
        body: 'sqflite stores rows',
        pinned: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Pinned notes come first.
    final ordered = await repository.all();
    expect(ordered.first.pinned, isTrue);

    // Keyword search runs against the title and the content.
    final titleHits = await repository.search('Grocery', SearchScope.title);
    expect(titleHits, hasLength(1));

    final contentHits = await repository.search('sqflite', SearchScope.content);
    expect(contentHits, hasLength(1));

    final noHits = await repository.search('nothing-here', SearchScope.both);
    expect(noHits, isEmpty);

    await repository.delete(firstId);
    expect(await repository.all(), hasLength(1));
  });

  test('theme choice is stored in shared_preferences', () async {
    final controller = await buildController();
    expect(controller.themeMode, ThemeMode.system);

    await controller.setThemeMode(ThemeMode.dark);
    final restored = await PreferencesStore.load();
    expect(restored.themeMode, ThemeMode.dark);
  });

  testWidgets('shows stored notes on the home screen', (tester) async {
    // Platform channels and sqflite need the real event loop, so the setup
    // runs inside runAsync instead of the widget test's fake async zone.
    late AppController controller;
    await tester.runAsync(() async {
      controller = await buildController();
      final now = DateTime.now();
      await controller.repository.insert(
        Note(
          title: 'Weekly plan',
          body: 'Finish the local storage assignment',
          pinned: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await controller.initialize();
    });

    await tester.pumpWidget(HansApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Weekly plan'), findsWidgets);
    expect(find.text('Pinned Notes'), findsOneWidget);

    // "All Notes" sits below the fold, so scroll the list before checking it.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('All Notes'), findsOneWidget);
  });

  testWidgets('add note form validates the title', (tester) async {
    late AppController controller;
    await tester.runAsync(() async {
      controller = await buildController();
    });

    await tester.pumpWidget(HansApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('No notes yet'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    // The new-note form autofocuses its title field, so the blinking text
    // cursor never lets pumpAndSettle finish; pump a fixed number of frames.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Add Note'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(find.text('Title is required'), findsOneWidget);
  });
}
