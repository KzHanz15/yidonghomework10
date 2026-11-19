import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_controller.dart';
import '../app/app_navigation.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({
    super.key,
    required this.controller,
    required this.noteId,
  });

  final AppController controller;
  final int noteId;

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this note?'),
        content: Text(
          '"${note.title}" will be removed from your local database. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await controller.deleteNote(note);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final note = controller.noteById(noteId);
        if (note == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This note no longer exists.')),
          );
        }

        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final updated = DateFormat('d MMM yyyy · HH:mm').format(note.updatedAt);
        final created = DateFormat('d MMM yyyy · HH:mm').format(note.createdAt);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Note Detail'),
            actions: [
              IconButton(
                tooltip: note.pinned ? 'Unpin note' : 'Pin note',
                onPressed: () => controller.togglePin(note),
                icon: Icon(
                  note.pinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: note.pinned ? scheme.secondary : null,
                ),
              ),
              IconButton(
                tooltip: 'Edit note',
                onPressed: () =>
                    openNoteEditor(context, controller, note: note),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete note',
                onPressed: () => _confirmDelete(context, note),
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(
                    note.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (note.pinned)
                        _MetaChip(
                          icon: Icons.push_pin_rounded,
                          label: 'Pinned',
                          highlighted: true,
                        ),
                      _MetaChip(
                        icon: Icons.update_rounded,
                        label: 'Updated $updated',
                      ),
                      _MetaChip(
                        icon: Icons.event_outlined,
                        label: 'Created $created',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Divider(),
                  const SizedBox(height: 22),
                  SelectableText(
                    note.hasBody ? note.body : 'This note has no content yet.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.7,
                      color: note.hasBody
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.togglePin(note),
                          icon: Icon(
                            note.pinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 18,
                          ),
                          label: Text(note.pinned ? 'Unpin' : 'Pin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              openNoteEditor(context, controller, note: note),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Note'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, note),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(
                        color: scheme.error.withValues(alpha: 0.4),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Note'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = highlighted ? scheme.secondary : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.secondary.withValues(alpha: 0.12)
            : scheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: highlighted
              ? scheme.secondary.withValues(alpha: 0.3)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color.withValues(alpha: highlighted ? 1 : 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: highlighted ? 1 : 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
