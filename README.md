# Hans Smart Local Notes

A local-first note taking app built with Flutter for **Android** and **Windows**.
Every note stays on the device: notes live in **SQLite**, the theme choice in
**shared_preferences**, and backups are written to a **JSON file**.

Built for the Lecture 10 local storage assignment (主题记忆 + sqflite 备忘录 +
关键词搜索 + JSON 导出).

## Download

Public download page: **https://37knwclxos978kh8ciw.traesite.cn**

The QR code in [download_page/qr-download.png](download_page/qr-download.png) encodes the
direct APK link, so scanning it starts the download immediately:

`https://37knwclxos978kh8ciw.traesite.cn/hans-smart-local-notes-arm64.apk`

| File | Platform | Size |
| --- | --- | --- |
| `download_page/hans-smart-local-notes-arm64.apk` | Android 7+ (arm64, most phones) | 17.4 MB |
| `download_page/hans-smart-local-notes-armv7.apk` | Android 7+ (32-bit devices) | 14.9 MB |
| `download_page/HansSmartLocalNotes-Windows.zip` | Windows 10/11 x64 | 11.8 MB |

The Windows zip is the whole release folder plus the Visual C++ runtime DLLs, so it
runs on a clean machine: extract it and start `hans_smart_local_notes.exe`.

## Screenshots and progress report

The `screenshots/` folder holds real Windows app captures of every checkpoint:
home (light/dark), all notes, add note, note detail, edit, delete confirmation,
search results, settings, JSON export, and the theme surviving a restart
(`screenshots/13-theme-restored-after-restart.png`).

The ten-section progress report required by the assignment is in
[docs/progress-report-10.md](docs/progress-report-10.md).

## Features

Modules follow the submitted mind map:

| Module | Contents |
| --- | --- |
| Home Page | Header & logo, search bar, pinned notes, recent notes, all notes, add note (+) |
| Add Note | Note title, note content, pin note, save, cancel |
| Note Detail | View title, view content, edit note, delete note, pin / unpin |
| Search | Search keyword, search results, search title, search content, clear search |
| Settings | Light mode, dark mode, system default, theme memory, export JSON, about app |
| Data Storage | SQLite (notes), shared_preferences (theme), JSON file (export), save / load |
| Platform | Android, Windows, Flutter, Dart, responsive UI (bottom navigation on phones, navigation rail on desktop) |

Extra behaviour beyond the mind map:

- Pinned notes are sorted first by the database (`ORDER BY pinned DESC, updatedAt DESC`).
- Search runs a parameterised SQL `LIKE` query — user input is never concatenated into SQL.
- Empty search results and an empty note list both show a friendly state instead of a blank screen.
- The theme is loaded from shared_preferences before the first frame, so there is no
  light→dark flash on launch.
- Export reports the absolute path of the generated JSON file and lets you copy it.

## Storage decisions

The three questions from the guide, answered for this app:

1. **One snapshot or many records?** Many records — each note is an independent row, so SQLite.
2. **Do we need conditional queries?** Yes — keyword search and pinned-first ordering, which is
   exactly what `WHERE ... LIKE ?` and `ORDER BY` are for.
3. **Is the data sensitive?** No passwords or tokens are stored. Only the theme preference
   (shared_preferences) and note text in the app-private database directory.

| Storage | Used for | Why |
| --- | --- | --- |
| `shared_preferences` | Theme mode (`theme_mode`) | One tiny key that must survive a restart |
| `sqflite` | `notes` table | Structured records with search, sorting and pinning |
| JSON file (`path_provider`) | Manual export | Whole-dataset snapshot the user can take away |

### Database schema

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  pinned INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
);
```

All sqflite calls are awaited, all writes use `where: 'id = ?'` with `whereArgs`,
and every screen reads from a single `AppController` so the list, the detail page
and the search results always agree.

### Export format

`Settings → Export JSON` writes `hans_notes_<timestamp>.json` to the application
documents directory:

```json
{
  "app": "Hans Smart Local Notes",
  "version": "1.0.0",
  "exportedAt": "2026-11-19T10:00:00.000",
  "count": 2,
  "notes": [
    {
      "id": 1,
      "title": "Grocery list",
      "body": "Milk and bread",
      "pinned": false,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

## Project structure

```
lib/
├── main.dart                  # platform SQLite factory + app bootstrap
├── app/
│   ├── app_controller.dart    # notes state, theme state, export
│   ├── hans_app.dart          # MaterialApp + responsive shell
│   └── app_navigation.dart    # detail / editor routes
├── data/
│   ├── note_repository.dart   # sqflite CRUD, search, ordering
│   ├── preferences_store.dart # shared_preferences wrapper
│   └── export_service.dart    # JSON snapshot writer
├── models/note.dart
├── screens/                   # home, add/edit, detail, search, settings
├── theme/app_theme.dart
└── widgets/                   # note card, empty state, brand mark, section header
```

On Windows and Linux there is no native sqflite plugin, so `main.dart` swaps in
`sqflite_common_ffi`; Android uses the standard sqflite plugin. `pubspec.yaml`
points the `sqlite3` package at the system SQLite library (`winsqlite3.dll` on
Windows) so no binary is downloaded at build time.

## Run it

```bash
flutter pub get
flutter run -d windows      # Windows desktop
flutter run                 # connected Android device / emulator
```

## Build it

```bash
# Android APKs (release, one per ABI so the download stays small)
flutter build apk --release --split-per-abi
# -> build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Windows (requires Visual Studio "Desktop development with C++")
flutter build windows --release
# -> build/windows/x64/runner/Release/
```

Regenerate the launcher icon and the download QR code:

```bash
dart run tool/generate_icon.dart
dart run flutter_launcher_icons
dart run tool/generate_qr.dart \
  "https://37knwclxos978kh8ciw.traesite.cn/hans-smart-local-notes-arm64.apk" \
  "download_page/qr-download.png"
```

The public page in `download_page/` is the same folder uploaded to the static host;
`index.html` links the APKs and the Windows zip next to the QR image.

Tests: `flutter test` (repository CRUD/search, theme persistence, UI smoke tests).

## AI usage disclosure

This project was built with AI assistance (Trae AI) as allowed by the assignment.
What the AI produced, and how it was verified:

| Area | AI contribution | Verification |
| --- | --- | --- |
| Data layer (`note_repository.dart`, `preferences_store.dart`, `export_service.dart`) | Generated from the patterns in the practice guide (parameterised queries, awaited Futures, `onCreate` DDL) | `flutter test` covers insert / pin ordering / title + content search / delete and theme persistence |
| UI screens | Generated from the mind map structure | `flutter analyze` clean; widget tests for home rendering and editor validation; manual run on the Windows build |
| Platform wiring (sqflite_common_ffi, manifest label, runner title) | Generated | Windows app launched and notes survived an app restart |

AI suggestions were reviewed line by line; anything that could not be verified
(no test, no manual checkpoint) was removed rather than kept.

## Checkpoints

- Theme survives a restart: the mode is written to shared_preferences on change and
  read back in `AppController.initialize()` before `runApp`.
- CRUD: create, list (pinned first), edit, delete, pin/unpin.
- Search: keyword search with title / content / both scope and a friendly empty state.
- Export: a JSON snapshot of all notes in the documents directory.
