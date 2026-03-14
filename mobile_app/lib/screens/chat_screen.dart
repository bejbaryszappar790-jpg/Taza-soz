import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _currentLanguage = "Русский";

  // Серверден келетін құжаттың ID-і осы жерде сақталады
  String? _currentDocId;

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

  // 1. Фото арқылы талдау
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      File imageFile = File(photo.path);
      setState(() {
        _messages.add({"role": "user", "text": "📸 Фото отправлено"});
      });

      // Жаңа ApiService.uploadDocument қолданамыз
      var result = await ApiService.uploadDocument(imageFile);

      if (result.containsKey('document_id')) {
        _currentDocId = result['document_id'];
        setState(() {
          _messages.add({
            "role": "ai",
            "text": _currentLanguage == "Русский"
                ? "Фото получено! Теперь можете задавать вопросы."
                : "Фото қабылданды! Енді сұрақтар қоя аласыз.",
          });
        });
      } else {
        _showError(result['error'] ?? "Ошибка загрузки");
      }
    }
  }

  // 2. Құжат (PDF/Doc) жүктеу
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _messages.add({
          "role": "user",
          "text": "📎 Файл: ${result.files.single.name}",
        });
      });

      var uploadResult = await ApiService.uploadDocument(file);

      if (uploadResult.containsKey('document_id')) {
        _currentDocId = uploadResult['document_id'];
        setState(() {
          _messages.add({
            "role": "ai",
            "text": _currentLanguage == "Русский"
                ? "Документ проанализирован. Что вы хотите узнать?"
                : "Құжат талданды. Не білгіңіз келеді?",
          });
        });
      } else {
        _showError(uploadResult['error'] ?? "Ошибка");
      }
    }
  }

  // 3. ИИ-мен чат
  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      if (_currentDocId == null) {
        _showError(
          _currentLanguage == "Русский"
              ? "Сначала загрузите документ!"
              : "Алдымен құжатты жүктеңіз!",
        );
        return;
      }

      setState(() {
        _messages.add({"role": "user", "text": text});
        _controller.clear();
      });

      // Жаңа ApiService.chatWithAI қолданамыз
      var aiResponse = await ApiService.chatWithAI(_currentDocId!, text);

      setState(() {
        _messages.add({
          "role": "ai",
          "text": aiResponse['summary'] ?? "Кешіріңіз, жауап ала алмадым.",
        });
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build бөлімі өзгеріссіз қалады...
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsScreen(initialLanguage: _currentLanguage),
                ),
              );
              if (result != null && result is String) {
                setState(() => _currentLanguage = result);
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
