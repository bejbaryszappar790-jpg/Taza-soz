import 'settings_screen.dart';
import 'dart:io'; // Добавь это
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart'; // Добавь это
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../services/api_service.dart'; // Добавь это

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // Контроллер камеры

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

  // Функция для камеры
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      File imageFile = File(photo.path);

      setState(() {
        _messages.add({"role": "user", "text": "📸 Фото отправлено"});
      });

      // Отправляем фото на сервер
      String response = await ApiService.uploadImage(imageFile);

      setState(() {
        _messages.add({"role": "ai", "text": response});
      });
    }
  }

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
          "text": "Құжат қабылданды. Талдау жасауға бірнеше секунд беріңіз...",
        });
      });
    }
  }

  // ОБНОВЛЕННАЯ ОТПРАВКА ТЕКСТА
  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({"role": "user", "text": text});
        _controller.clear();
      });

      // Ждем ответ от нашего сервиса
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
        title: Text(
          "Taza Soz AI",
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
          onPressed: () {
            // Если хочешь, чтобы стрелочка назад работала:
            Navigator.pop(context);
          },
        ),
        // ВОТ ЭТО МЫ ДОБАВИЛИ:
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
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
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
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
                icon: const Icon(
                  Icons.add,
                  color: AppColors.iconActive,
                  size: 28,
                ),
                onPressed: _pickDocument,
              ),
              // НОВАЯ КНОПКА КАМЕРЫ
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.iconActive,
                  size: 24,
                ),
                onPressed: _takePhoto,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask anything...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.iconActive,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
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
