import 'dart:convert'; // Для jsonDecode
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  // Базовий URL для OpenWeatherMap
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Future<WeatherModel> - це як suspend fun fetchWeather(): WeatherModel в Kotlin
  Future<WeatherModel> fetchWeather(String cityName) async {
    // Дістаємо наш ключ з файлу .env
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

    if (apiKey == null) {
      throw Exception('API Key not found in .env file');
    }

    // Формуємо лінку.
    // units=metric - щоб температура була в Цельсіях, а не Фаренгейтах
    // lang=uk - щоб опис погоди був українською!
    final url = Uri.parse('$_baseUrl?q=$cityName&appid=$apiKey&units=metric&lang=uk');

    try {
      // Робимо GET запит
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Якщо все ок, розпаковуємо JSON і передаємо в нашу модель
        final jsonMap = jsonDecode(response.body);
        return WeatherModel.fromJson(jsonMap);
      } else {
        // Якщо сервер повернув помилку (наприклад, 404 - місто не знайдено)
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      // Ловимо помилки мережі (немає інтернету тощо)
      throw Exception('Network error: $e');
    }
  }

  // Нова функція для пошуку за координатами
  Future<WeatherModel> fetchWeatherByLocation(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null) throw Exception('API Key not found');

    // Формуємо лінку, але вже з параметрами lat та lon
    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=uk');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return WeatherModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
