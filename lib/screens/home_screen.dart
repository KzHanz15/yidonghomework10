import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_controller.dart';
import '../app/app_navigation.dart';
import '../models/note.dart';
import '../widgets/brand_mark.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenSearch,
    required this.onAddNote,
  });

  final AppController controller;
  final VoidCallback onOpenSearch;
  final VoidCallback onAddNote;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final notes = controller.notes;
        final pinned = controller.pinnedNotes;
        final recent = controller.recentNotes;

        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 900 ? 40.0 : 20.0;
            return CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _HomeHeader(
                      noteCount: notes.length,
                      pinnedCount: controller.pinnedCount,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBarButton(onTap: onOpenSearch),
                  ),
                ),
                if (notes.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 40),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.edit_note_rounded,
                        title: 'No notes yet',
                        message:
                            'Everything you write is stored on this device in a '
                            'local SQLite database. Create your first note to begin.',
                        action: FilledButton.icon(
                          onPressed: onAddNote,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Create your first note'),
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (pinned.isNotEmpty) ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                          title: 'Pinned Notes',
                          trailing: '${pinned.length}',
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      sliver: SliverList.separated(
                        itemCount: pinned.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final note = pinned[index];
                          return NoteCard(
                            note: note,
                            showBody: false,
                            onTap: () =>
                                openNoteDetail(context, controller, note),
                            onTogglePin: () => controller.togglePin(note),
                          );
                        },
                      ),
                    ),
                  ],
                  if (recent.isNotEmpty) ...[
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 0),
                      sliver: const SliverToBoxAdapter(
                        child: SectionHeader(title: 'Recent Notes'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 128,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          itemCount: recent.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final note = recent[index];
                            return _RecentNoteCard(
                              note: note,
                              onTap: () =>
                                  openNoteDetail(context, controller, note),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 26, horizontal, 0),
                    sliver: SliverToBoxAdapter(
                      child: SectionHeader(
                        title: 'All Notes',
                        trailing: '${notes.length}',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 40),
                    sliver: SliverList.separated(
                      itemCount: notes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteCard(
                          note: note,
                          onTap: () => openNoteDetail(context, controller, note),
                          onTogglePin: () => controller.togglePin(note),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.noteCount, required this.pinnedCount});

  final int noteCount;
  final int pinnedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandMark(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hans Smart Local Notes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Local-first notes · SQLite + shared_preferences',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _StatChip(
              icon: Icons.description_outlined,
              label: '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
            ),
            _StatChip(
              icon: Icons.push_pin_outlined,
              label: '$pinnedCount pinned',
            ),
            _StatChip(
              icon: Icons.cloud_off_rounded,
              label: 'Offline',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search by title or content…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Open',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentNoteCard extends StatelessWidget {
  const _RecentNoteCard({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final date = DateFormat('d MMM').format(note.updatedAt);

    return SizedBox(
      width: 216,
      child: Material(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      note.pinned
                          ? Icons.push_pin_rounded
                          : Icons.sticky_note_2_outlined,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const Spacer(),
                Text(
                  note.hasBody ? note.body.replaceAll('\n', ' ') : 'No content',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
