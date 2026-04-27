import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class AiService {
  Future<String?> generateDynamicSummary(
      WeatherModel weather,
      String unitStr,
      ) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.trim().isEmpty) {
        return 'Помилка ШІ. Ключ не знайдено у файлі .env';
      }

      final prompt = '''
      Уяви що ти метеоролог у додатку "Cloudy". Напиши короткий, але змістовний прогноз погоди для міста ${weather.cityName} українською мовою.
      
      Дані:
      - Стан: ${weather.description}
      - Температура: ${weather.temperature}$unitStr (відчувається як ${weather.feelsLike}$unitStr)
      - Вітер: ${weather.windSpeed} м/с
      - Опади: ${weather.precipitation} мм
      - Час доби: ${weather.partOfDay}
      
      ОБОВ'ЯЗКОВІ ВИМОГИ ДО ТЕКСТУ:
      1. Текст має складатися з 2-3 зв'язних речень (один суцільний абзац). ЗАБОРОНЕНО писати лише одне слово чи одне речення.
      2. ОПИШИ ПОГОДУ своїми словами (це головне завдання, не обмежуйся лише привітанням!).
      3. Органічно вплети побажання відповідно до часу доби (${weather.partOfDay}).
      4. Додай коротку пораду (наприклад, чи брати парасолю, чи варто тепло одягатися, чи гарний час для прогулянки).
      5. Гарантовано заверши останню думку і постав крапку в кінці тексту.
      
      Уникай списків, маркдауну (ніяких зірочок чи жирного шрифту) та сухих цифр. Пиши тепло і природно, як жива людина.
      ''';

      final content = [Content.text(prompt)];

      final modelsToTry = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash',
        'gemini-pro',
      ];

      String lastError = '';

      for (final modelName in modelsToTry) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              maxOutputTokens: 8192,
            ),
            safetySettings: [
              SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
              SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
            ],
          );

          final response = await model.generateContent(content).timeout(const Duration(seconds: 15));
          final result = response.text?.trim();

          if (result != null && result.isNotEmpty) {
            return result.replaceAll('**', '').replaceAll('*', '');
          }
        } on TimeoutException {
          lastError = 'Таймаут відповіді для $modelName';
        } catch (e) {
          lastError = e.toString();
        }
      }
      return 'Помилка ШІ. Жодна версія моделі не підтримується. Остання помилка: $lastError';
    } catch (e) {
      return 'Критична помилка ШІ: $e';
    }
  }
}