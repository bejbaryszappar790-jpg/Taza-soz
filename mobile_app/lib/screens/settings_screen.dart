import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final String initialLanguage;
  const SettingsScreen({super.key, this.initialLanguage = "Русский"});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _userName = "Бейбарыс";
  late String _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.initialLanguage;
  }

  // НОВАЯ ФУНКЦИЯ ДЛЯ TELEGRAM
  Future<void> _launchTelegram() async {
    // Замени 'tazasoz_bot' на реальный username твоего бота, когда создашь его
    final Uri url = Uri.parse("https://t.me/tazasoz_bot");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch Telegram");
      }
    } catch (e) {
      debugPrint("Telegram Error: $e");
    }
  }

  void _editName() {
    TextEditingController nameController = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentLanguage == "Русский" ? "Изменить имя" : "Атты өзгерту",
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: _currentLanguage == "Русский"
                ? "Введите имя"
                : "Есіміңізді енгізіңіз",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_currentLanguage == "Русский" ? "Отмена" : "Бас тарту"),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() => _userName = nameController.text);
              }
              Navigator.pop(context);
            },
            child: Text(_currentLanguage == "Русский" ? "Сохранить" : "Сақтау"),
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
        centerTitle: true,
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
          onPressed: () => Navigator.pop(context, _currentLanguage),
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
            subtitle: _currentLanguage == "Русский"
                ? "Нажмите, чтобы изменить"
                : "Атыңызды өзгерту үшін басыңыз",
            onTap: _editName,
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(_currentLanguage == "Русский" ? "Общее" : "Жалпы"),
          _buildSettingsTile(
            icon: Icons.language,
            title: "Тіл / Язык",
            subtitle: _currentLanguage,
            onTap: () {
              setState(
                () => _currentLanguage = _currentLanguage == "Русский"
                    ? "Қазақша"
                    : "Русский",
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none_outlined,
            title: _currentLanguage == "Русский"
                ? "Уведомления"
                : "Хабарландырулар",
            subtitle: _notificationsEnabled ? "On" : "Off",
            trailing: Switch(
              value: _notificationsEnabled,
              activeColor: AppColors.iconActive,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            onTap: () =>
                setState(() => _notificationsEnabled = !_notificationsEnabled),
          ),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: _currentLanguage == "Русский"
                ? "Темная тема"
                : "Қараңғы режим",
            subtitle: _isDarkMode ? "On" : "Off",
            trailing: Switch(
              value: _isDarkMode,
              activeColor: AppColors.iconActive,
              onChanged: (v) => setState(() => _isDarkMode = v),
            ),
            onTap: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(
            _currentLanguage == "Русский" ? "Поддержка" : "Қолдау",
          ),
          // ТЕПЕРЬ ТУТ TELEGRAM
          _buildSettingsTile(
            icon: Icons.send_rounded, // Иконка, похожая на самолетик Telegram
            title: "Telegram Bot",
            subtitle: _currentLanguage == "Русский"
                ? "Написать в поддержку"
                : "Қолдау қызметіне жазу",
            onTap: _launchTelegram,
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, _currentLanguage),
              child: Text(
                _currentLanguage == "Русский" ? "Выйти / Шығу" : "Шығу",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
        onTap: onTap,
      ),
    );
  }
}
