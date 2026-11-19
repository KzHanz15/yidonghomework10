# 第十次作业进度报告 — Hans Smart Local Notes

> 课程：移动软件开发 · 第十讲 本地存储
> 项目：Hans Smart Local Notes（Flutter，Android + Windows）
> 仓库：https://github.com/KzHanz15/yidonghomework10

## 一、任务概述

本次作业要求先复现案例 `local_store`（主题模式记忆、sqflite 备忘录 CRUD、关键词搜索、JSON 导出），再自主实现一个具备同样本地存储能力的应用。本项目实现了一个本地优先的笔记应用：所有笔记保存在设备本地的 SQLite 数据库中，主题偏好保存在 shared_preferences 中，并提供整库 JSON 导出备份。同一套 Dart 代码同时构建 Android APK 与 Windows 桌面版。

## 二、运行环境与技术栈

| 项目 | 说明 |
| --- | --- |
| Flutter / Dart | Flutter 3.47.6 / Dart 3.13.5，Material 3 |
| Android | minSdk 24（Android 7.0+），arm64-v8a / armeabi-v7a |
| Windows | Windows 10/11 x64，Visual Studio 2022 C++ 工具链 |
| 数据库 | `sqflite`（Android）、`sqflite_common_ffi` + 系统 `winsqlite3.dll`（Windows） |
| 偏好存储 | `shared_preferences`（键：`theme_mode`） |
| 文件导出 | `path_provider` + `dart:convert`（缩进 JSON） |
| 测试 | `flutter test`（4 个测试）、`dart analyze`（0 issue） |

## 三、案例复现

| 案例功能 | 本项目实现 | 状态 |
| --- | --- | --- |
| 主题模式记忆 | `PreferencesStore` 读写 `theme_mode`，`AppController.initialize()` 在 `runApp` 之前加载 | 完成 |
| Light / Dark / 跟随系统 | 设置页三个选项 + 顶部 “Theme memory” 说明条 | 完成 |
| sqflite 备忘录 CRUD | `NoteRepository` 的 `insert / update / delete / all / findById` | 完成 |
| 关键词搜索 | `WHERE (title LIKE ? OR body LIKE ?)` 参数化查询，可切换 Title / Content / Both | 完成 |
| JSON 导出 | `exportNotesAsJson`，写入文档目录并显示、可复制绝对路径 | 完成 |
| 响应式界面 | ≥900px 用 NavigationRail，窄屏用 NavigationBar | 完成 |

## 四、关键代码

建表语句（`lib/data/note_repository.dart`）：

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

参数化搜索 + 置顶优先排序：

```dart
final rows = await _db.query(
  'notes',
  where: scope == SearchScope.title
      ? 'title LIKE ?'
      : scope == SearchScope.content
          ? 'body LIKE ?'
          : '(title LIKE ? OR body LIKE ?)',
  whereArgs: scope == SearchScope.both
      ? ['%$keyword%', '%$keyword%']
      : ['%$keyword%'],
  orderBy: 'pinned DESC, updatedAt DESC',
);
```

主题持久化（启动前加载，避免闪白）：

```dart
final store = await PreferencesStore.create();
final controller = AppController(repository: repo, preferences: store);
await controller.initialize(); // 读取 theme_mode
runApp(HansApp(controller: controller));
```

Windows 没有原生 sqflite 插件，因此在 `main.dart` 中切换实现：

```dart
if (Platform.isWindows || Platform.isLinux) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

## 五、检查点结果（重启保持与 CRUD 截图）

| 检查点 | 结果 | 截图 |
| --- | --- | --- |
| 主页（Pinned / Recent / All Notes） | 通过 | `screenshots/01-home-light.png`、`screenshots/15-home-all-notes.png` |
| 新建笔记 | 通过，列表从 6 条变为 7 条，置顶在前 | `screenshots/03-add-note-form.png`、`04-add-note-filled.png`、`05-home-after-save.png` |
| 查看详情 | 通过 | `screenshots/06-note-detail.png` |
| 编辑笔记 | 通过，保存后内容更新 | `screenshots/07-edit-note.png`、`08-detail-after-edit.png` |
| 删除笔记 | 通过，弹出确认对话框 | `screenshots/09-delete-confirm.png` |
| 关键词搜索 | 通过，`sqflite` 命中 2 条，含 Clear 按钮 | `screenshots/10-search-results.png` |
| 主题切换 | 通过 | `screenshots/02-settings-light.png`、`11-settings-dark.png`、`12-home-dark.png` |
| **重启后主题保持** | 通过：关闭进程后重新打开，仍为 Dark Mode | `screenshots/13-theme-restored-after-restart.png` |
| JSON 导出 | 通过：导出 7 条笔记并显示路径 | `screenshots/14-export-json.png` |

导出文件示例：`hans_notes_20261119_160914.json`，内容包含 `app / version / exportedAt / count / notes[]`。

## 六、问题与调试

| 问题 | 原因 | 解决 |
| --- | --- | --- |
| Windows 运行时报 “databaseFactory not initialized” | 桌面端没有 sqflite 原生插件 | 启动时改用 `sqflite_common_ffi` 并调用 `sqfliteFfiInit()` |
| 构建时尝试从 GitHub 下载 sqlite3 二进制失败 | 网络无法访问 GitHub Releases | 在 `pubspec.yaml` 的 `hooks.user_defines.sqlite3` 中指定使用系统库 `winsqlite3.dll` |
| Windows 构建提示需要符号链接权限 | Flutter 插件的 CMake 构建需要 symlink | 开启 Windows 开发者模式后重新构建成功 |
| Android 构建在中文路径下失败 | Gradle 路径校验 | 在 `android/gradle.properties` 添加 `android.overridePathCheck=true` |
| Widget 测试卡死 | 假异步环境中等待平台通道 Future | 初始化放入 `tester.runAsync`，并把 `pumpAndSettle` 改为有界 `pump` |
| `ListTile` 背景色断言失败 | 自行包裹了 Container 改变 Ink 材质 | 改用 `Material` + `SwitchListTile.adaptive` |

## 七、自主实践完成情况

- **主题记忆**：默认 `ThemeMode.system`，用户选择 Light/Dark 后写入 shared_preferences；重启后仍保持。
- **数据库 CRUD**：新建、读取、更新、删除全部实现；置顶笔记通过 `ORDER BY pinned DESC, updatedAt DESC` 排在前面。
- **条件查询 + 空状态**：搜索支持标题/正文/两者，输入防抖 250ms；无结果时显示 “No notes found” 空状态，而不是空白页。
- **界面**：桌面宽屏用 NavigationRail，手机窄屏用底部 NavigationBar；空列表也有引导状态。

## 八、AI 使用标注

| 部分 | AI 参与内容 | 人工验证方式 |
| --- | --- | --- |
| 数据层（`note_repository.dart` / `preferences_store.dart` / `export_service.dart`） | 依据实验指导中的模式生成建表、参数化查询、导出代码 | `flutter test`：插入 / 置顶排序 / 标题与正文搜索 / 删除 / 主题持久化 |
| 界面（主页、编辑、详情、搜索、设置） | 依据思维导图结构生成 | `dart analyze` 无问题；Windows 实机逐页操作并截图 |
| 平台接线（FFI、窗口标题、清单名称） | 生成平台适配代码 | 重新打开应用确认主题与数据仍在 |

无法验证的 AI 建议已删除，未保留无用代码。

## 九、存储选型说明

| 存储 | 用途 | 理由 |
| --- | --- | --- |
| `shared_preferences` | 主题模式（`theme_mode`） | 单个小键值，需要跨重启保留 |
| `sqflite` | `notes` 表 | 多条结构化记录，需要条件查询与排序 |
| JSON 文件 | 手动导出 | 整库快照，便于备份或带走 |

三问结论：① 多条记录而非单快照 → SQLite；② 需要条件查询（LIKE、置顶排序）→ SQLite；③ 不存密码等敏感信息，笔记只落在应用私有目录。

## 十、提交物清单与总结

- 源码：`lib/`（数据层、界面、主题、组件），原生工程：`android/`、`windows/`
- 文档：`README.md`（功能、选型、构建命令、AI 使用说明）
- 截图：`screenshots/`（15 张，含重启保持与 CRUD）
- 安装包：`download_page/hans-smart-local-notes-arm64.apk`、`...-armv7.apk`、`HansSmartLocalNotes-Windows.zip`
- 下载页与二维码：`download_page/index.html`、`download_page/qr-download.png`（扫码直接下载 APK）
- 部署地址：https://37knwclxos978kh8ciw.traesite.cn

总结：本项目用同一套 Flutter 代码在 Android 与 Windows 上实现了完整的本地笔记功能，并通过数据库与偏好存储分别承担结构化数据和轻量配置，达到本次作业“本地存储 + 主题记忆 + 条件查询 + 数据导出”的目标。
