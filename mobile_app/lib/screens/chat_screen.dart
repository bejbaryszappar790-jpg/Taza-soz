import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
// Импортируем настройки и тему
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  // Конструктор должен быть таким, чтобы main.dart не ругался
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Состояние языка (по умолчанию)
  String _currentLanguage = "Русский";

  // Твои сообщения (прогресс сохранен)
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "ai",
      "text":
          "Сәлем! Мен Taza Soz-бын. Құжатты жүктеңіз немесе фото жіберіңіз.",
    },
    {
      "role": "ai",
      "text": "Привет! Я Taza Soz. Загрузите документ или отправьте фото.",
    },
  ];

  // Функция для камеры (прогресс сохранен)
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      File imageFile = File(photo.path);
      setState(() {
        _messages.add({"role": "user", "text": "📸 Фото отправлено"});
      });
      String response = await ApiService.uploadImage(imageFile);
      setState(() {
        _messages.add({"role": "ai", "text": response});
      });
    }
  }

  // Функция для документов (прогресс сохранен)
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      setState(() {
        _messages.add({
          "role": "user",
          "text": "📎 Файл: ${result.files.single.name}",
        });
        _messages.add({
          "role": "ai",
          "text": _currentLanguage == "Русский"
              ? "Документ принят. Дайте мне пару секунд..."
              : "Құжат қабылданды. Талдау жасауға бірнеше секунд беріңіз...",
        });
      });
    }
  }

  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({"role": "user", "text": text});
        _controller.clear();
      });
      String aiResponse = await ApiService.sendMessage(text);
      setState(() {
        _messages.add({"role": "ai", "text": aiResponse});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Taza Soz AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () async {
              // ПЕРЕДАЕМ текущий язык в настройки и ЖДЕМ результат назад
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(initialLanguage: _currentLanguage),
                ),
              );

              // Если язык в настройках изменили, обновляем главный экран
              if (result != null && result is String) {
                setState(() {
                  _currentLanguage = result;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                return ChatBubble(
                  text: msg["text"]!,
                  isAi: msg["role"] == "ai",
                );
              },
            ),
          ),
          _buildInputPanel(),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      color: AppColors.background,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.iconActive),
                onPressed: _pickDocument,
              ),
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.iconActive,
                ),
                onPressed: _takePhoto,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    // ВОТ ТУТ ЯЗЫК МЕНЯЕТСЯ АВТОМАТИЧЕСКИ
                    hintText: _currentLanguage == "Русский"
                        ? "Спросите о чем угодно..."
                        : "Сұрағыңызды жазыңыз...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: AppColors.iconActive,
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
