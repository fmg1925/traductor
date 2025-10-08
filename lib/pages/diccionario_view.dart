import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class DiccionarioView extends StatefulWidget {
  const DiccionarioView({super.key});
  @override
  State<DiccionarioView> createState() => _DiccionarioViewState();
}

class _DiccionarioViewState extends State<DiccionarioView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<String>('word_cache');
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          t.dictionary,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onPrimary,
            fontSize: 24,
          ),
        ),
        actions: [const SizedBox(width: 8)],
      ),
      body: ValueListenableBuilder<Box<String>>(
        valueListenable: box.listenable(),
        builder: (context, b, _) {
          final raw = Map<String, String>.from(b.toMap());

          raw.removeWhere((key, _) {
            final p = key.split('::');
            return p.length != 3 || p[1] == p[2];
          });

          final q = _search.text.trim().toLowerCase();
          final entries = raw.entries.where((e) {
            if (q.isEmpty) return true;
            final k = e.key.toLowerCase();
            final v = e.value.toLowerCase();
            return k.contains(q) || v.contains(q);
          }).toList()..sort((a, b) => a.key.compareTo(b.key));

          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.no_words,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SearchField(controller: _search),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: entries.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == 0) return _SearchField(controller: _search);
              final e = entries[i - 1];
              final parts = e.key.split('::');
              final word = parts[0];
              final path = '${parts[1]} → ${parts[2]}';

              return Dismissible(
                key: ValueKey(e.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) async {
                  await b.delete(e.key);
                  if (!mounted) return;
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                        children: [
                          TextSpan(text: word),
                          TextSpan(
                            text: '  =  ',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: e.value,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            path,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: t.delete,
                      icon: const Icon(Icons.more_vert),
                      onPressed: () async {
                        final picked = await showModalBottomSheet<bool>(
                          context: context,
                          showDragHandle: true,
                          backgroundColor: theme.colorScheme.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          builder: (ctx) => SafeArea(
                            child: ListTile(
                              leading: const Icon(Icons.delete_outline),
                              title: Text(t.delete),
                              onTap: () => Navigator.pop(ctx, true),
                            ),
                          ),
                        );
                        if (picked == true) {
                          await b.delete(e.key);
                          if (!mounted) return;
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: scheme.onPrimary),
        decoration: InputDecoration(
          hintText: t.search,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => (context as Element).markNeedsBuild(),
      ),
    );
  }
}
