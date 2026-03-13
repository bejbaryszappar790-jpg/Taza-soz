import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. Создаем переменную состояния для темы
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Меняем цвет фона в зависимости от состояния
      backgroundColor: _isDarkMode
          ? const Color(0xFF121212)
          : AppColors.background,
      appBar: AppBar(
        title: Text(
          "Баптаулар / Настройки",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _isDarkMode
            ? const Color(0xFF1E1E1E)
            : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: _isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle("Жалпы / Общее"),

          // Элемент с переключателем темы
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: "Қараңғы режим",
            subtitle: "Темная тема",
            trailing: Switch(
              value: _isDarkMode, // Текущее значение
              activeColor: AppColors.iconActive,
              onChanged: (bool value) {
                // 3. САМОЕ ВАЖНОЕ: setState заставляет экран перерисоваться
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
            onTap: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white10
              : AppColors.inputBorder.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.iconActive),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: _isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
