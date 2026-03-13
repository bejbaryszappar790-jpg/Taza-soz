import 'package:flutter/material.dart';

class AppColors {
  // Базовые цвета
  static const Color background = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A); // Глубокий серый
  static const Color textSecondary = Color(
    0xFF757575,
  ); // Серый для подзаголовков

  // Цвета AI (Светло-серый, как в шаблоне)
  static const Color aiBubble = Color(0xFFF2F2F7);
  static const Color aiText = textPrimary;

  // Цвета Пользователя (Пастельно-голубой акцент)
  static const Color userBubble = Color(0xFFE1F5FE);
  static const Color userText = Color(0xFF01579B); // Темно-синий для контраста

  // Элементы интерфейса
  static const Color iconActive = Color(0xFF0277BD); // Синий акцент для кнопок
  static const Color iconInactive = Color(0xFFBDBDBD);
  static const Color inputBorder = Color(0xFFE0E0E0);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.iconActive,
        background: AppColors.background,
      ),
      // Стили текста
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
        bodySmall: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      // Тема AppBar (чистый, без теней)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}
