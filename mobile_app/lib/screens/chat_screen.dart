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

  // Деректерді ChatScreen деңгейінде сақтаймыз (Бұл біздің прогресс)
  String _currentLanguage = "Русский";
  String _userName = "Бейбарыс";

  String? _currentDocId;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "role": "ai",
      "text": "Привет! Я Taza Soz. Загрузите документ или отправьте фото.",
    },
  ];

  // 1. Фото арқылы талдау
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _processFile(File(photo.path), "📸 Фото отправлено");
    }
  }

  // 2. Құжат жүктеу
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      _processFile(
        File(result.files.single.path!),
        "📎 Файл: ${result.files.single.name}",
      );
    }
  }

  // Файлды серверге жіберу
  Future<void> _processFile(File file, String userMessage) async {
    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _isLoading = true;
    });

    try {
      var result = await ApiService.uploadDocument(file);
      if (result.containsKey('document_id')) {
        _currentDocId = result['document_id'];
        _addAiMessage(
          _currentLanguage == "Русский"
              ? "Документ получен! Теперь можете задавать вопросы."
              : "Құжат қабылданды! Енді сұрақтар қоя аласыз.",
        );
      } else {
        _showError(result['error'] ?? "Ошибка загрузки");
      }
    } catch (e) {
      _showError("Ошибка связи с сервером");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. ИИ-мен чат
  void _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

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
      _isLoading = true;
    });

    try {
      var aiResponse = await ApiService.chatWithAI(_currentDocId!, text);
      _addAiMessage(
        aiResponse['summary'] ??
            (aiResponse['error'] ?? "Кешіріңіз, қате шықты."),
      );
    } catch (e) {
      _showError("Ошибка сервера");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addAiMessage(String text) {
    setState(() {
      _messages.add({"role": "ai", "text": text});
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // МІНЕ, ОСЫ ЖЕРДІ ӨЗГЕРТТІК: ${_userName} АЛЫП ТАСТАЛДЫ
        title: const Text(
          "Taza Soz AI",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    initialLanguage: _currentLanguage,
                    initialName: _userName,
                  ),
                ),
              );

              // Кері қайтқанда деректерді қабылдаймыз (бұл да прогресс)
              if (result != null && result is Map) {
                setState(() {
                  _currentLanguage = result['language'] ?? _currentLanguage;
                  _userName = result['name'] ?? _userName;
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
              padding: const EdgeInsets.all(16),
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          _buildInputPanel(),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.add), onPressed: _pickDocument),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: _takePhoto,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _currentLanguage == "Русский"
                        ? "Спросите..."
                        : "Сұраңыз...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: AppColors.iconActive,
                  child: Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
