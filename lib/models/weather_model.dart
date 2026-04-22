class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;

  // Конструктор
  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
  });

  // Це аналог десеріалізації (парсингу JSON).
  // factory - це ключове слово для створення об'єкта класу (схоже на companion object у Kotlin)
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'],
      // OpenWeatherMap іноді повертає int (наприклад 20), а іноді double (20.5).
      // toDouble() захищає нас від крашів.
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      iconCode: json['weather'][0]['icon'],
    );
  }
}