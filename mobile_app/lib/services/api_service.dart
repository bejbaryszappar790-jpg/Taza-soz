import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Құрбыңның компьютерінің нақты IP-адресі
  static const String baseUrl = 'http://10.75.0.136:8000';

  // 1. Файлды (PDF немесе Сурет) серверге жүктеу
  // Бұл функция құрбыңның @app.post("/upload") нүктесіне сәйкес келеді
  static Future<Map<String, dynamic>> uploadDocument(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

      // Бэкент файлды 'file' деген кілтпен күтеді
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Бұл жерде бізге document_id келеді
        return jsonDecode(response.body);
      } else {
        return {"error": "Сервер қатесі: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Файлды жіберу мүмкін болмады: $e"};
    }
  }

  // 2. ИИ-мен сөйлесу (Chat)
  // Бұл функция құрбыңның @app.post("/chat") нүктесіне сәйкес келеді
  static Future<Map<String, dynamic>> chatWithAI(
    String docId,
    String question,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'document_id': docId, 'question': question}),
      );

      if (response.statusCode == 200) {
        // utf8.decode маңызды! Әйтпесе қазақша әріптер "???" болып көрінеді
        final String decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      } else {
        return {"summary": "Қате: ${response.statusCode}"};
      }
    } catch (e) {
      return {"summary": "Серверге қосылу мүмкін болмады. IP тексер!"};
    }
  }
}
