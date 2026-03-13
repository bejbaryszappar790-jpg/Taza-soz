import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Состояние темной темы
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // РАЗДЕЛ ПРОФИЛЬ
          _buildSectionTitle("Профиль"),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: "Бейбарыс",
            subtitle: "Менің деректерім / Мои данные",
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // РАЗДЕЛ ОБЩЕЕ
          _buildSectionTitle("Жалпы / Общее"),
          _buildSettingsTile(
            icon: Icons.language,
            title: "Тіл / Язык",
            subtitle: "Қазақша / Русский",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: "Қараңғы режим",
            subtitle: "Темная тема",
            trailing: Switch(
              value: _isDarkMode,
              activeColor: AppColors.iconActive,
              onChanged: (bool value) {
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
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: "Хабарландырулар",
            subtitle: "Уведомления",
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // РАЗДЕЛ ПОДДЕРЖКА
          _buildSectionTitle("Қолдау / Поддержка"),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: "Көмек орталығы",
            subtitle: "Помощь",
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: "Қосымша туралы",
            subtitle: "О приложении",
            onTap: () {},
          ),

          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                "Шығу / Выйти",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Вспомогательный виджет для заголовков секций
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.white70 : AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Вспомогательный виджет для плиток настроек
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
            fontWeight: FontWeight.w600, // Здесь была ошибка (обрыв кода)
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
