import 'package:flutter/material.dart';
import 'package:traductor/entities/translation.dart';
import 'package:traductor/main.dart';
import 'package:traductor/pages/home.dart';
import '../domain/providers/data_provider.dart';

class PracticeView extends StatefulWidget {
  const PracticeView({
    super.key,
    this.provider,
    this.initialSourceLang = 'auto',
    this.initialTargetLang = 'es',
  });

  final DataProvider? provider;
  final String initialSourceLang;
  final String initialTargetLang;

  @override
  State<StatefulWidget> createState() => _PracticeViewState();
}

class _PracticeViewState extends State<PracticeView> {
  late final DataProvider provider;
  late String sourceLang;
  late String targetLang;

  Future<Translation>? translationFuture;

  @override
  void initState() {
    super.initState();
    provider = widget.provider ?? DataProvider();
    sourceLang = widget.initialSourceLang;
    targetLang = widget.initialTargetLang;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _generar() {
    setState(() {
      translationFuture = fetchTranslation(provider, sourceLang, targetLang);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pinkAccent,
      body: Column(
        children: [
          languageDropdown(),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1F1617).withAlpha(50),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _generar, child: const Text('Generar')),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TranslationsArea(
                future: translationFuture,
                targetLang: targetLang,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding languageDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: DropdownButton<String>(
              value: sourceLang,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() => sourceLang = value);
                }
              },
              itemHeight: 60,
              items: languages(context).entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: targetLang,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    targetLang = value;
                  });
                }
              },
              items: languages(context).entries.where((e) => e.key != 'auto').map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
