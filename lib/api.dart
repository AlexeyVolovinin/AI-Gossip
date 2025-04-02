// lib/api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://flutter-tpg4.onrender.com';
const _systemQuery = r"""
[ИНСТРУКЦИИ ДЛЯ ОТВЕТА]
1. Все ответы в Markdown
2. Если инлайн формула то в $: $f(x) = \sum_{i=0}^{n} \frac{a_i}{1+x}$
3. Если блоковая формула:
$$
c = \pm\sqrt{a^2 + b^2}
$$
4. Правильные переносы строк
5. Код в блоках
6. Язык ответа = язык запроса
7. Обязательно исправлять ошибки
""";

/// Отправляет запрос на сервер и возвращает ответ от ИИ-модели.
///
/// [userInput] - запрос пользователя.
/// [model] - выбранная ИИ-модель.
Future<String> sendQuery(String userInput, String model) async {
  // Формируем полный запрос, добавляя системное сообщение
  final fullQuery = '$_systemQuery\n\n[ЗАПРОС]\n$userInput';
  
  // Отправляем POST-запрос на сервер
  final response = await http.post(
    Uri.parse(_baseUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'input': fullQuery, 'model': model}),
  );
  
  // Проверяем статус ответа
  if (response.statusCode != 200) {
    throw Exception('Сервер вернул статус ${response.statusCode}');
  }
  
  // Декодируем тело ответа как UTF-8 и парсим JSON
  final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
  
  // Проверяем, есть ли поле "answer" в ответе
  if (!jsonResponse.containsKey('answer')) {
    throw Exception('Ответ сервера не содержит поле "answer"');
  }
  
  // Возвращаем значение поля "answer"
  return jsonResponse['answer'];
}