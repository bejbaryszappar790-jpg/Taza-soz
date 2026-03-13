import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Для WhatsApp и Email
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true; // Оживили уведомления
  String _userName = "Бейбарыс"; // Имя теперь переменная
  String _currentLanguage = "Русский"; // Состояние языка

  // Функция для WhatsApp
  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/77718559377");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  // Функция для Почты
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'arailymalimurat@gmail.com',
      queryParameters: {'subject': 'Taza Soz Support'},
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint("Could not launch Email");
    }
  }

  // Функция смены имени через диалоговое окно
  void _editName() {
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Изменить имя"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Введите ваше имя"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _userName = nameController.text);
              Navigator.pop(context);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF121212)
          : AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentLanguage == "Русский" ? "Настройки" : "Баптаулар",
          style: TextStyle(
            color: _isDarkMode ? Colors.white : AppColors.textPrimary,
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
          _buildSectionTitle(
            _currentLanguage == "Русский" ? "Профиль" : "Профиль",
          ),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: _userName,
            subtitle: "Нажмите, чтобы изменить имя",
            onTap: _editName, // Теперь можно менять имя
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(_currentLanguage == "Русский" ? "Общее" : "Жалпы"),
          _buildSettingsTile(
            icon: Icons.language,
            title: "Тіл / Язык",
            subtitle: _currentLanguage,
            onTap: () {
              setState(() {
                _currentLanguage = _currentLanguage == "Русский"
                    ? "Қазақша"
                    : "Русский";
              });
            },
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: "Темная тема",
            subtitle: "Қараңғы режим",
            trailing: Switch(
              value: _isDarkMode,
              activeColor: AppColors.iconActive,
              onChanged: (v) => setState(() => _isDarkMode = v),
            ),
            onTap: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: "Уведомления",
            subtitle: _notificationsEnabled ? "Включены" : "Выключены",
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: AppColors.iconActive,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            onTap: () =>
                setState(() => _notificationsEnabled = !_notificationsEnabled),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(
            _currentLanguage == "Русский" ? "Поддержка" : "Қолдау",
          ),
          _buildSettingsTile(
            icon: Icons.chat_outlined,
            title: "WhatsApp",
            subtitle: "+7 771 855 9377",
            onTap: _launchWhatsApp, // Открывает WhatsApp
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: "arailymalimurat@gmail.com",
            onTap: _launchEmail, // Открывает почту
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Выйти / Шығу",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
