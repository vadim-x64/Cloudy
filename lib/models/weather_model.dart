class WeatherModel {
  final String cityName;
  final String region;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String iconCode;
  final String mainCondition;
  final int humidity;
  final double windSpeed;
  final double precipitation; // Додано об'єм опадів
  final DateTime localTime;
  final DateTime sunrise;
  final DateTime sunset;

  WeatherModel({
    required this.cityName,
    required this.region,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.iconCode,
    required this.mainCondition,
    required this.humidity,
    required this.windSpeed,
    required this.precipitation,
    required this.localTime,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherModel.fromJson(
    Map<String, dynamic> json,
    String cityName,
    String region,
    String country,
  ) {
    int timezoneOffset = json['timezone'] ?? 0;

    DateTime calcLocalTime = DateTime.now().toUtc().add(
      Duration(seconds: timezoneOffset),
    );

    DateTime calcSunrise = DateTime.fromMillisecondsSinceEpoch(
      json['sys']['sunrise'] * 1000,
      isUtc: true,
    ).add(Duration(seconds: timezoneOffset));
    DateTime calcSunset = DateTime.fromMillisecondsSinceEpoch(
      json['sys']['sunset'] * 1000,
      isUtc: true,
    ).add(Duration(seconds: timezoneOffset));

    // Витягуємо дані про опади (дощ або сніг за останню годину)
    double precip = 0.0;
    if (json['rain'] != null && json['rain']['1h'] != null) {
      precip = (json['rain']['1h'] as num).toDouble();
    } else if (json['snow'] != null && json['snow']['1h'] != null) {
      precip = (json['snow']['1h'] as num).toDouble();
    }

    return WeatherModel(
      cityName: cityName,
      region: region,
      country: country,
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
      mainCondition: json['weather'][0]['main'],
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      precipitation: precip,
      localTime: calcLocalTime,
      sunrise: calcSunrise,
      sunset: calcSunset,
    );
  }

  bool get isDayTime {
    return localTime.isAfter(sunrise) && localTime.isBefore(sunset);
  }

  // === РОЗРАХУНОК ЧАСТИН ДНЯ ===
  String get partOfDay {
    final double timeInHours = localTime.hour + (localTime.minute / 60.0);
    final double sunriseTime = sunrise.hour + (sunrise.minute / 60.0);
    final double sunsetTime = sunset.hour + (sunset.minute / 60.0);

    // Світанок і Сутінки (в межах +/- 45 хв від сходу/заходу)
    if ((timeInHours - sunriseTime).abs() <= 0.75) return 'Світанок';
    if ((timeInHours - sunsetTime).abs() <= 0.75) return 'Сутінки';

    // Інші частини дня
    if (timeInHours > sunriseTime && localTime.hour < 12) return 'Ранок';
    if (localTime.hour == 12) return 'Полудень';
    if (localTime.hour > 12 && timeInHours < sunsetTime) return 'День';
    if (timeInHours > sunsetTime && localTime.hour < 23) return 'Вечір';
    return 'Ніч';
  }
}

// === МОДЕЛЬ ДЛЯ ВИПАДАЮЧОГО СПИСКУ МІСТ ===
class CitySuggestion {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;

  CitySuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
  });

  factory CitySuggestion.fromJson(
    Map<String, dynamic> json,
    String translatedCountry,
    String translatedRegion,
  ) {
    final localNames = json['local_names'] ?? {};
    final ukName = localNames['uk'] ?? json['name'];

    return CitySuggestion(
      name: ukName,
      region: translatedRegion,
      country: translatedCountry,
      lat: json['lat'],
      lon: json['lon'],
    );
  }
}

// === СПЕЦІАЛЬНИЙ КЛАС ДЛЯ ПОМИЛОК ГЕОЛОКАЦІЇ ===
class LocationException implements Exception {
  final String code;
  final String message;

  LocationException(this.code, this.message);

  @override
  String toString() => message;
}
