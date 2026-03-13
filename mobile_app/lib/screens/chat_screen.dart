import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "ai",
      "text":
          "Сәлем! Мен Taza Soz-бын. Құжатты жүктеңіз, мен оны қарапайым тілмен түсіндіріп беремін.",
    },
    {
      "role": "ai",
      "text":
          "Привет! Я Taza Soz. Загрузите документ, и я объясню его простым языком.",
    },
  ];

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

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({"role": "user", "text": _controller.text.trim()});
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Чистый AppBar без разделителей
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
          onPressed: () {}, // Заглушка
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {}, // Заглушка
          ),
        ],
      ),
      body: Column(
        children: [
          // Область чата
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              reverse: true, // Новые сообщения снизу
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                // Из-за reverse: true инвертируем индекс
                final msg = _messages[_messages.length - 1 - index];
                return ChatBubble(
                  text: msg["text"]!,
                  isAi: msg["role"] == "ai",
                );
              },
            ),
          ),
          // Панель ввода (Супер-скругленная, как на Dribbble)
          _buildInputPanel(),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), // Больше отступ снизу
      decoration: BoxDecoration(
        color: AppColors.background,
        // Легкая тень сверху панели
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
            borderRadius: BorderRadius.circular(32), // Максимальное скругление
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              // Кнопка скрепки с подсветкой при нажатии
              IconButton(
                icon: const Icon(
                  Icons.add,
                  color: AppColors.iconActive,
                  size: 28,
                ),
                splashRadius: 24, // Радиус подсветки
                onPressed: _pickDocument,
              ),
              // Поле ввода
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: "Ask anything...",
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              // Кнопка отправки (Круглая, синяя)
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
                  splashRadius: 24,
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
