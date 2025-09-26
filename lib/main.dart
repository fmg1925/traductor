import 'package:flutter/material.dart';
import 'package:traductor/pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/web_title.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('word_cache');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setWebTitle("Trilingo");
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Fira Code'),
      home: HomePage()
    );
  }
}