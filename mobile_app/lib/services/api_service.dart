import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Пока ты тестируешь на симуляторе, используй этот адрес.
  // Если будешь тестировать на реальном iPhone, нужно будет вписать IP компа.
  static const String baseUrl = 'http://127.0.0.1:8000';

  // 1. Функция для отправки ОБЫЧНОГО ТЕКСТА
  static Future<String> sendMessage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        return "Ошибка сервера: ${response.statusCode}";
      }
    } catch (e) {
      return "Сервер недоступен. Проверь подключение!";
    }
  }

  // 2. Функция для отправки ФОТО (Multipart)
  static Future<String> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-photo'),
      );

      // Добавляем файл в запрос под ключом 'file' (так его ждет Python)
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message']; // Ответ от подруги: "Фото дошло!"
      } else {
        return "Ошибка при загрузке фото: ${response.statusCode}";
      }
    } catch (e) {
      return "Не удалось отправить фото.";
    }
  }
}
