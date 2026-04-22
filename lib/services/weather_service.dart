import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

class WeatherService {
  static const String _weatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _geoUrl = 'https://api.openweathermap.org/geo/1.0';

  // === ПЕРЕКЛАДАЧ КРАЇН ===
  String translateCountry(String code) {
    const Map<String, String> countries = {
      'UA': 'Україна',
      'PL': 'Польща',
      'US': 'США',
      'GB': 'Велика Британія',
      'DE': 'Німеччина',
      'FR': 'Франція',
      'IT': 'Італія',
      'ES': 'Іспанія',
      'CA': 'Канада',
      'AU': 'Австралія',
      'JP': 'Японія',
      'CN': 'Китай',
      'CZ': 'Чехія',
      'SK': 'Словаччина',
      'RO': 'Румунія',
      'MD': 'Молдова',
      'HU': 'Угорщина',
      'AT': 'Австрія',
      'CH': 'Швейцарія',
      'SE': 'Швеція',
      'NO': 'Норвегія',
      'FI': 'Фінляндія',
      'DK': 'Данія',
      'NL': 'Нідерланди',
      'BE': 'Бельгія',
      'PT': 'Португалія',
      'GR': 'Греція',
      'TR': 'Туреччина',
      'BR': 'Бразилія',
      'AR': 'Аргентина',
      'MX': 'Мексика',
      'IN': 'Індія',
      'IL': 'Ізраїль',
      'GE': 'Грузія',
      'LT': 'Литва',
      'LV': 'Латвія',
      'EE': 'Естонія',
    };
    return countries[code] ?? code; // Якщо країни немає в списку, виведе код
  }

  // === ПЕРЕКЛАДАЧ ОБЛАСТЕЙ ===
  String cleanRegionName(String? region) {
    if (region == null || region.isEmpty) return '';
    return region.replaceAll(' Oblast', ' обл.').replaceAll('Oblast', 'обл.');
  }

  // === ОТРИМАННЯ ПІДКАЗОК ДЛЯ ВИПАДАЮЧОГО СПИСКУ ===
  Future<List<CitySuggestion>> fetchCitySuggestions(String query) async {
    if (query.length < 2) return []; // Не шукаємо, якщо менше 2 букв

    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_geoUrl/direct?q=$query&limit=5&appid=$apiKey'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) {
          return CitySuggestion.fromJson(
            json,
            translateCountry(json['country'] ?? ''),
            cleanRegionName(json['state']),
          );
        }).toList();
      }
    } catch (e) {
      // Якщо помилка (немає інтернету), просто повертаємо пустий список
      return [];
    }
    return [];
  }

  // Отримання погоди за вибраними координатами (з автодоповнення або GPS)
  Future<WeatherModel> fetchWeatherByCoordinates(
    double lat,
    double lon, [
    String? knownCityName,
  ]) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null) throw Exception('API Key not found');

    try {
      String ukName = knownCityName ?? 'Невідоме місце';
      String region = '';
      String country = '';

      // Якщо ми не знаємо точної назви (наприклад пошук йде суто по GPS), робимо реверс-геокодинг
      if (knownCityName == null) {
        final geoResponse = await http.get(
          Uri.parse('$_geoUrl/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey'),
        );
        if (geoResponse.statusCode == 200) {
          final List geoData = jsonDecode(geoResponse.body);
          if (geoData.isNotEmpty) {
            final localNames = geoData[0]['local_names'] ?? {};
            ukName = localNames['uk'] ?? geoData[0]['name'];
            region = cleanRegionName(geoData[0]['state']);
            country = translateCountry(geoData[0]['country'] ?? '');
          }
        }
      }

      final weatherUrl = Uri.parse(
        '$_weatherUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=uk',
      );
      final response = await http.get(weatherUrl);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        return WeatherModel.fromJson(jsonMap, ukName, region, country);
      } else {
        throw Exception('Не вдалося завантажити погоду');
      }
    } catch (e) {
      throw Exception('Помилка підключення: $e');
    }
  }
}
