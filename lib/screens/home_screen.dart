import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  final _locationService = LocationService();

  // Контролер для поля вводу (щоб читати текст, який ввів користувач)
  final _searchController = TextEditingController();

  WeatherModel? _weather;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeatherByLocation(); // При старті шукаємо за GPS
  }

  // Функція 1: Отримання погоди за GPS
  Future<void> _loadWeatherByLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final weather = await _weatherService.fetchWeatherByLocation(position.latitude, position.longitude);
      setState(() => _weather = weather);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Функція 2: Отримання погоди за назвою міста (з поля вводу)
  Future<void> _loadWeatherByCity(String cityName) async {
    if (cityName.isEmpty) return; // Якщо нічого не ввели - ігноруємо

    // Ховаємо клавіатуру після натискання пошуку
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(cityName);
      setState(() {
        _weather = weather;
        _searchController.clear(); // Очищаємо поле вводу після успіху
      });
    } catch (e) {
      setState(() => _errorMessage = 'Місто не знайдено');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Очищення контролера при знищенні екрану (добра практика, щоб уникнути витоків пам'яті)
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold.body дозволяє малювати на всьому екрані, ми прибрали AppBar для краси
      body: Container(
        width: double.infinity, // Розтягуємо на всю ширину
        decoration: const BoxDecoration(
          // Робимо красивий синій градієнт
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // SafeArea не дає контенту залізти під "чубчик" телефону чи статус-бар
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // --- ВЕРХНІЙ БЛОК: ПОШУК ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Введіть місто...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2), // Напівпрозорий фон
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        // Якщо юзер натиснув "Enter" на клавіатурі
                        onSubmitted: _loadWeatherByCity,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Кнопка локації (GPS)
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: const Icon(Icons.my_location, color: Colors.white),
                        onPressed: _loadWeatherByLocation,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Кнопка пошуку (Лупа)
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () => _loadWeatherByCity(_searchController.text),
                      ),
                    ),
                  ],
                ),

                const Spacer(), // Гумовий відступ, який штовхає контент вниз

                // --- ЦЕНТРАЛЬНИЙ БЛОК: ПОГОДА ---
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 18))
                else if (_weather != null)
                    Column(
                      children: [
                        // ВАУ-ЕФЕКТ: Картинка з інтернету в 1 рядок коду!
                        // @4x означає, що ми просимо в API картинку високої якості
                        // ВАУ-ЕФЕКТ: Картинка з інтернету в 1 рядок коду!
                        Image.network(
                          'https://openweathermap.org/img/wn/${_weather!.iconCode}@4x.png',
                          width: 150,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud_off, size: 100, color: Colors.white),
                        ),

                        Text(
                          _weather!.cityName,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${_weather!.temperature.round()}°C',
                          style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200, color: Colors.white),
                        ),
                        Text(
                          _weather!.description.toUpperCase(),
                          style: const TextStyle(fontSize: 24, color: Colors.white70),
                        ),
                      ],
                    )
                  else
                    const Text('Немає даних', style: TextStyle(color: Colors.white)),

                const Spacer(flex: 2), // Ще один гумовий відступ знизу
              ],
            ),
          ),
        ),
      ),
    );
  }
}