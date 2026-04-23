import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

enum TempUnit { celsius, fahrenheit, kelvin }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  final _locationService = LocationService();

  WeatherModel? _weather;
  bool _isLoading = false;
  String? _errorMessage;

  TempUnit _selectedUnit = TempUnit.celsius;

  @override
  void initState() {
    super.initState();
    _loadWeatherByLocation();
  }

  String _formatTemp(double tempC) {
    switch (_selectedUnit) {
      case TempUnit.fahrenheit:
        return '${(tempC * 9 / 5 + 32).round()}°F';
      case TempUnit.kelvin:
        return '${(tempC + 273.15).round()}K';
      case TempUnit.celsius:
      default:
        return '${tempC.round()}°';
    }
  }

  // Конвертація hPa у мм рт. ст.
  String _formatPressure(int hPa) {
    return '${(hPa * 0.750062).round()} мм рт.ст.';
  }

  // Розшифровка індексу якості повітря
  Map<String, dynamic> _getAqiInfo(int aqi) {
    switch (aqi) {
      case 1:
        return {'text': 'Відмінно', 'color': Colors.greenAccent};
      case 2:
        return {'text': 'Добре', 'color': Colors.lightGreen};
      case 3:
        return {'text': 'Помірно', 'color': Colors.yellowAccent};
      case 4:
        return {'text': 'Погано', 'color': Colors.orangeAccent};
      case 5:
        return {'text': 'Небезпечно', 'color': Colors.redAccent};
      default:
        return {'text': 'Невідомо', 'color': Colors.white};
    }
  }

  Future<void> _loadWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final weather = await _weatherService.fetchWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() => _weather = weather);
    } catch (e) {
      if (e is LocationException) {
        _showLocationErrorDialog(e);
        setState(
          () => _errorMessage =
              'Немає доступу до геолокації. Введіть місто вручну.',
        );
      } else {
        setState(() => _errorMessage = 'Сталася помилка: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationErrorDialog(LocationException error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blueGrey.shade900,
        title: const Text('Увага', style: TextStyle(color: Colors.white)),
        content: Text(
          error.message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрити', style: TextStyle(color: Colors.grey)),
          ),
          if (error.code == 'gps_disabled')
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Увімкнути GPS',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          if (error.code == 'permission_denied_forever')
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'В налаштування',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadWeatherBySuggestion(CitySuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeatherByCoordinates(
        suggestion.lat,
        suggestion.lon,
        suggestion.name,
      );

      setState(() {
        _weather = WeatherModel(
          cityName: weather.cityName,
          region: suggestion.region,
          country: suggestion.country,
          temperature: weather.temperature,
          feelsLike: weather.feelsLike,
          description: weather.description,
          iconCode: weather.iconCode,
          mainCondition: weather.mainCondition,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          precipitation: weather.precipitation,
          pressure: weather.pressure,
          aqi: weather.aqi,
          localTime: weather.localTime,
          sunrise: weather.sunrise,
          sunset: weather.sunset,
          hourlyForecast: weather.hourlyForecast,
          dailyForecast: weather.dailyForecast,
        );
      });
    } catch (e) {
      setState(() => _errorMessage = 'Не вдалося завантажити погоду');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getUkrainianWeekday(int weekday) {
    const days = [
      'Понеділок',
      'Вівторок',
      'Середа',
      'Четвер',
      'П\'ятниця',
      'Субота',
      'Неділя',
    ];
    return days[weekday - 1];
  }

  String _getShortWeekday(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
    return days[weekday - 1];
  }

  String _cleanWeatherDescription(String raw) {
    String desc = raw
        .toLowerCase()
        .replaceAll('рвані хмари', 'хмарно з проясненнями')
        .replaceAll('уривчасті хмари', 'мінлива хмарність')
        .replaceAll('кілька хмар', 'малохмарно')
        .replaceAll('чисте небо', 'ясно')
        .replaceAll('мряка', 'дрібний дощ');
    return desc.isEmpty ? '' : '${desc[0].toUpperCase()}${desc.substring(1)}';
  }

  List<Color> _getBackgroundColors() {
    if (_weather == null) return [Colors.blue.shade900, Colors.blue.shade400];
    bool isDay = _weather!.isDayTime;
    String condition = _weather!.mainCondition.toLowerCase();

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return isDay
          ? [Colors.blueGrey.shade800, Colors.grey.shade400]
          : [Colors.grey.shade900, Colors.blueGrey.shade900];
    } else if (condition.contains('snow')) {
      return isDay
          ? [Colors.blue.shade200, Colors.white]
          : [Colors.blueGrey.shade900, Colors.blue.shade900];
    } else if (condition.contains('cloud')) {
      return isDay
          ? [Colors.blue.shade700, Colors.grey.shade300]
          : [Colors.indigo.shade900, Colors.blueGrey.shade900];
    } else {
      return isDay
          ? [Colors.blue.shade600, Colors.lightBlue.shade200]
          : [const Color(0xFF0D1B2A), const Color(0xFF1B263B)];
    }
  }

  String _getLottieAnimation() {
    if (_weather == null)
      return 'https://lottie.host/80ccecf6-a841-4547-86f2-bb44dffaa75a/z7J3g7yF3D.json';
    bool isDay = _weather!.isDayTime;
    String condition = _weather!.mainCondition.toLowerCase();

    if (condition.contains('rain') || condition.contains('drizzle'))
      return 'https://lottie.host/17e2c943-7f30-4e00-8dce-095cdb5a03e6/F2P1n1kZ1u.json';
    if (condition.contains('snow'))
      return 'https://lottie.host/797c0f1c-7f51-40c2-8419-f0db381e74a8/N0i1f1R0tX.json';
    if (condition.contains('cloud'))
      return isDay
          ? 'https://lottie.host/ea9174df-3f62-43bb-a320-b4f0b2f8e1fa/C1a1N1c1A1.json'
          : 'https://lottie.host/711cf2cb-2374-42b7-8798-7de7b9e0f31c/D1S1a1F1a1.json';
    return isDay
        ? 'https://lottie.host/9e530b80-1a76-4d56-a059-4d64bc86bb78/K1l1x1E1P1.json'
        : 'https://lottie.host/f6b9c9f4-18e3-4f93-8b7f-0e1b3d7c5885/Z1r1w1V1H1.json';
  }

  Widget _buildThermometer(double tempC) {
    double minT = -30;
    double maxT = 40;
    double range = maxT - minT;
    double percent = ((tempC - minT) / range).clamp(0.0, 1.0);

    return SizedBox(
      height: 120,
      width: 45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 12,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
                FractionallySizedBox(
                  heightFactor: (percent * 0.75) + 0.15,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 8,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  right: 6,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(7, (index) {
                  bool isMajor = index % 2 == 0;
                  return Container(
                    height: 2,
                    width: isMajor ? 12 : 6,
                    color: Colors.white70,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(seconds: 2),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getBackgroundColors(),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // --- ВЕРХНІЙ БЛОК: ПОШУК ТА КНОПКИ ---
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<CitySuggestion>(
                            optionsBuilder:
                                (TextEditingValue textEditingValue) async {
                                  return await _weatherService
                                      .fetchCitySuggestions(
                                        textEditingValue.text,
                                      );
                                },
                            displayStringForOption: (CitySuggestion option) =>
                                option.name,
                            onSelected: _loadWeatherBySuggestion,
                            fieldViewBuilder:
                                (
                                  context,
                                  controller,
                                  focusNode,
                                  onEditingComplete,
                                ) {
                                  return ValueListenableBuilder<
                                    TextEditingValue
                                  >(
                                    valueListenable: controller,
                                    builder: (context, value, child) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Пошук міста...',
                                          hintStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withOpacity(
                                            0.15,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.search,
                                            color: Colors.white70,
                                          ),
                                          suffixIcon: value.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(
                                                    Icons.clear,
                                                    color: Colors.white70,
                                                  ),
                                                  onPressed: () {
                                                    controller.clear();
                                                    focusNode.unfocus();
                                                  },
                                                )
                                              : null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 0,
                                              ),
                                        ),
                                      );
                                    },
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 130,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade900
                                          .withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(
                                            option.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${option.region.isNotEmpty ? '${option.region}, ' : ''}${option.country}',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          leading: const Icon(
                                            Icons.location_city,
                                            color: Colors.white70,
                                          ),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: PopupMenuButton<TempUnit>(
                            icon: const Icon(
                              Icons.thermostat,
                              color: Colors.white,
                              size: 22,
                            ),
                            color: Colors.blueGrey.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            onSelected: (unit) =>
                                setState(() => _selectedUnit = unit),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: TempUnit.celsius,
                                child: Text(
                                  '°C - Цельсій',
                                  style: TextStyle(
                                    color: _selectedUnit == TempUnit.celsius
                                        ? Colors.blueAccent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: TempUnit.fahrenheit,
                                child: Text(
                                  '°F - Фаренгейт',
                                  style: TextStyle(
                                    color: _selectedUnit == TempUnit.fahrenheit
                                        ? Colors.blueAccent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                value: TempUnit.kelvin,
                                child: Text(
                                  'K - Кельвін',
                                  style: TextStyle(
                                    color: _selectedUnit == TempUnit.kelvin
                                        ? Colors.blueAccent
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 22,
                            ),
                            onPressed: _loadWeatherByLocation,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- ГОЛОВНА ІНФОРМАЦІЯ ---
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (_weather != null)
                      Column(
                        children: [
                          Text(
                            _weather!.cityName,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 4),
                          Text(
                            '${_weather!.region.isNotEmpty ? '${_weather!.region}, ' : ''}${_weather!.country}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 15),
                          Text(
                            '${_getUkrainianWeekday(_weather!.localTime.weekday)}, ${DateFormat('d MMMM • HH:mm', 'uk_UA').format(_weather!.localTime)}\n${_weather!.partOfDay}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            height: 180,
                            child: Lottie.network(
                              _getLottieAnimation(),
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.network(
                                    'https://openweathermap.org/img/wn/${_weather!.iconCode}@4x.png',
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.cloud,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildThermometer(_weather!.temperature),
                              const SizedBox(width: 15),
                              Text(
                                _formatTemp(_weather!.temperature) +
                                    (_selectedUnit == TempUnit.celsius
                                        ? 'C'
                                        : ''),
                                style: const TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w200,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),

                          Text(
                            _cleanWeatherDescription(_weather!.description),
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 30),

                          // --- ПОГОДИННИЙ ПРОГНОЗ (24 години) ---
                          if (_weather!.hourlyForecast.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Прогноз на 24 години',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _weather!.hourlyForecast.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                itemBuilder: (context, index) {
                                  final hourly =
                                      _weather!.hourlyForecast[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 15,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'HH:mm',
                                          ).format(hourly.time),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Image.network(
                                          'https://openweathermap.org/img/wn/${hourly.iconCode}.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                        Text(
                                          _formatTemp(hourly.temperature),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],

                          // --- ПАНЕЛЬ ДЕТАЛЕЙ (Додано Тиск та AQI) ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildWeatherDetail(
                                      Icons.thermostat_auto,
                                      'Відчувається',
                                      _formatTemp(_weather!.feelsLike),
                                    ),
                                    _buildWeatherDetail(
                                      Icons.water_drop,
                                      'Вологість',
                                      '${_weather!.humidity}%',
                                    ),
                                    _buildWeatherDetail(
                                      Icons.umbrella,
                                      'Опади',
                                      '${_weather!.precipitation} мм',
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                  child: Divider(color: Colors.white24),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildWeatherDetail(
                                      Icons.air,
                                      'Вітер',
                                      '${_weather!.windSpeed} м/с\n${(_weather!.windSpeed * 3.6).toStringAsFixed(1)} км/г',
                                    ),
                                    _buildWeatherDetail(
                                      Icons.wb_twilight,
                                      'Схід',
                                      DateFormat(
                                        'HH:mm',
                                      ).format(_weather!.sunrise),
                                    ),
                                    _buildWeatherDetail(
                                      Icons.nights_stay,
                                      'Захід',
                                      DateFormat(
                                        'HH:mm',
                                      ).format(_weather!.sunset),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15.0),
                                  child: Divider(color: Colors.white24),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildWeatherDetail(
                                      Icons.speed,
                                      'Тиск',
                                      _formatPressure(_weather!.pressure),
                                    ),
                                    _buildWeatherDetail(
                                      Icons.masks,
                                      'Якість повітря',
                                      _getAqiInfo(_weather!.aqi)['text'],
                                      valueColor: _getAqiInfo(
                                        _weather!.aqi,
                                      )['color'],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // --- ЩОДЕННИЙ ПРОГНОЗ (5 днів) ---
                          if (_weather!.dailyForecast.isNotEmpty) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Прогноз на 5 днів',
                                // Безкоштовне API дає 5 днів, а не 7
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _weather!.dailyForecast.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(
                                      color: Colors.white24,
                                      height: 1,
                                    ),
                                itemBuilder: (context, index) {
                                  final daily = _weather!.dailyForecast[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            _getUkrainianWeekday(
                                              daily.date.weekday,
                                            ),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Image.network(
                                          'https://openweathermap.org/img/wn/${daily.iconCode}.png',
                                          width: 40,
                                          height: 40,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _formatTemp(daily.minTemp),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              _formatTemp(daily.maxTemp),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
