import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'app_controller.dart';
import 'app_navigation.dart';

class HansApp extends StatelessWidget {
  const HansApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hans Smart Local Notes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.themeMode,
          home: AppShell(controller: controller),
        );
      },
    );
  }
}

/// Layout shell: bottom bar on phones, navigation rail on tablets and desktop.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _openSearch() {
    setState(() => _index = 1);
  }

  Future<void> _addNote() => openNoteEditor(context, widget.controller);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      HomeScreen(
        controller: widget.controller,
        onOpenSearch: _openSearch,
        onAddNote: _addNote,
      ),
      SearchScreen(controller: widget.controller),
      SettingsScreen(controller: widget.controller),
    ];

    final content = SafeArea(
      child: IndexedStack(index: _index, children: pages),
    );

    return Scaffold(
      body: isWide
          ? Row(
              children: [
                _NavigationSide(selectedIndex: _index, onSelect: _select),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _addNote,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Note'),
            )
          : null,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.sticky_note_2_outlined),
                  selectedIcon: Icon(Icons.sticky_note_2_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  selectedIcon: Icon(Icons.saved_search_rounded),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }

  void _select(int index) {
    setState(() => _index = index);
  }
}

class _NavigationSide extends StatelessWidget {
  const _NavigationSide({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.only(top: 18, bottom: 22),
        child: BrandMark(size: 40),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.sticky_note_2_outlined),
          selectedIcon: Icon(Icons.sticky_note_2_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.search_rounded),
          selectedIcon: Icon(Icons.saved_search_rounded),
          label: Text('Search'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
