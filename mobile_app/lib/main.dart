import 'package:flutter/material.dart';
import 'theme/app_theme.dart'; // Наша тема
import 'screens/chat_screen.dart'; // Наш экран

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
      // Подключаем профессиональную тему
      theme: AppTheme.lightTheme,
      home: const ChatScreen(),
    );
  }
}
