import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../app/app_navigation.dart';
import '../data/note_repository.dart';
import '../models/note.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  Timer? _debounce;
  SearchScope _scope = SearchScope.both;
  List<Note> _results = const <Note>[];
  bool _hasSearched = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onNotesChanged);
    _queryController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNotesChanged);
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    if (_queryController.text.trim().isNotEmpty) {
      _runSearch();
    }
  }

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
  }

  Future<void> _runSearch() async {
    final keyword = _queryController.text.trim();
    if (keyword.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = const <Note>[];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await widget.controller.repository.search(keyword, _scope);
    if (!mounted) return;
    if (_queryController.text.trim() != keyword) return;
    setState(() {
      _results = results;
      _hasSearched = true;
      _isSearching = false;
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _queryController.clear();
    setState(() {
      _results = const <Note>[];
      _hasSearched = false;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final keyword = _queryController.text.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text(
              'Search',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Look up any note by title, content, or both.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Search keyword…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: keyword.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Search in',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ScopeChip(
                          label: 'Both',
                          selected: _scope == SearchScope.both,
                          onSelected: () => _selectScope(SearchScope.both),
                        ),
                        const SizedBox(width: 8),
                        _ScopeChip(
                          label: 'Title',
                          selected: _scope == SearchScope.title,
                          onSelected: () => _selectScope(SearchScope.title),
                        ),
                        const SizedBox(width: 8),
                        _ScopeChip(
                          label: 'Content',
                          selected: _scope == SearchScope.content,
                          onSelected: () => _selectScope(SearchScope.content),
                        ),
                      ],
                    ),
                  ),
                ),
                if (keyword.isNotEmpty)
                  TextButton(
                    onPressed: _clearSearch,
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isSearching)
              LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
              ),
            if (!_hasSearched && !_isSearching)
              const EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'Start typing to search',
                message:
                    'Keywords are matched with a parameterised SQL LIKE query, '
                    'so input is always treated as data — never as SQL code.',
              )
            else if (_hasSearched) ...[
              Row(
                children: [
                  Text(
                    _results.isEmpty
                        ? 'Search results'
                        : '${_results.length} '
                            '${_results.length == 1 ? 'result' : 'results'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_results.isNotEmpty)
                    Text(
                      'for "$keyword"',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_results.isEmpty)
                EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  message:
                      'No note contains "$keyword". Try another keyword or '
                      'switch the search scope.',
                  action: OutlinedButton.icon(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Clear Search'),
                  ),
                )
              else
                ..._results.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NoteCard(
                      note: note,
                      onTap: () =>
                          openNoteDetail(context, widget.controller, note),
                      onTogglePin: () => widget.controller.togglePin(note),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectScope(SearchScope scope) {
    setState(() => _scope = scope);
    if (_queryController.text.trim().isNotEmpty) {
      _runSearch();
    }
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}
