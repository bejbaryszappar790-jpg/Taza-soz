import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Баптаулар / Настройки",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 20),
          _buildSectionTitle("Профиль"),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: "Менің деректерім",
            subtitle: "Мои данные",
            onTap: () {},
          ),
          const SizedBox(height: 24),
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
            trailing: Switch(value: false, onChanged: (v) {}),
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: "Хабарландырулар",
            subtitle: "Уведомления",
            onTap: () {},
          ),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }

  // Заголовок секции
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Элемент списка настроек
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.iconActive),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            trailing ??
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
