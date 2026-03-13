import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isAi;

  const ChatBubble({super.key, required this.text, required this.isAi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isAi
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi) ...[
            // Аватарка AI (простой круг с иконкой)
            const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.aiBubble,
              child: Icon(
                Icons.psychology_outlined,
                size: 20,
                color: AppColors.iconActive,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Сам пузырь сообщения
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAi ? AppColors.aiBubble : AppColors.userBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(
                    isAi ? 4 : 24,
                  ), // Специфичное скругление
                  bottomRight: Radius.circular(isAi ? 24 : 4),
                ),
                // Мягкая тень для объема, как в Dribbble
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isAi ? AppColors.aiText : AppColors.userText,
                ),
              ),
            ),
          ),
          if (!isAi)
            const SizedBox(width: 40), // Отступ справа для пользователя
        ],
      ),
    );
  }
}
