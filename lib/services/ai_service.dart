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

      if (apiKey == null || apiKey.isEmpty) {
        return null;
      }

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt =
          '''
      Привіт друже. Треба твоя допомога. Ану-ка розкажи, що в нас там по погоді? Напиши динамічний прогноз десь типу до 3-х речень українською мовою.
      Проаналізуй дані та обов'язково додай доречну пораду (наприклад щодо одягу, парасолі тощо) й просто гарне побажання відповідно до часу доби.
      
      Дані про погоду в місті ${weather.cityName}:
      Стан: ${weather.description}
      Температура: ${weather.temperature}$unitStr
      Відчувається як: ${weather.feelsLike}$unitStr
      Вітер: ${weather.windSpeed} м/с
      Опади: ${weather.precipitation} мм
      Час доби: ${weather.partOfDay}
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text?.trim();
    } catch (e) {
      print('AI Error: $e');
      return null;
    }
  }
}
