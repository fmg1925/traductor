import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../l10n/app_localizations.dart';

class DiccionarioView extends StatelessWidget {
  const DiccionarioView({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<String>('word_cache'); // Caché local (diccionario)
    final t = AppLocalizations.of(context); // Traducciones
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: ValueListenableBuilder<Box<String>>(
        valueListenable: box.listenable(),
        builder: (context, b, _) {
          final palabras = Map<String, String>.from(b.toMap());

          palabras.removeWhere((key, _) {
            final p = key.split('::');
            return p.length != 3 || p[1] == p[2];
          });

          if (palabras.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: Text(
                  t.no_words,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            );
          }

          final entries = palabras.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final parts = e.key.split('::');
              final word = parts[0];
              final path = '${parts[1]} -> ${parts[2]}';
              return ListTile(
                title: Text('$word = ${e.value}'),
                subtitle: Text(path),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => b.delete(e.key),
                ),
              );
            },
          );
        },
      ),
    );
  }
}