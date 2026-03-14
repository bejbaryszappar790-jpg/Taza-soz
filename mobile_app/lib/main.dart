import 'package:flutter/material.dart';
// Используй относительный путь, если package-импорт не сработал:
import './theme/app_theme.dart';
import './screens/chat_screen.dart';

void main() {
  runApp(const TazaSozApp());
}

class TazaSozApp extends StatelessWidget {
  const TazaSozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taza Soz',
      theme: AppTheme.lightTheme,
      // Мы убрали const, это правильно
      home: ChatScreen(),
    );
  }
}
