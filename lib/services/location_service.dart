import 'package:geolocator/geolocator.dart';

class LocationService {
  // Функція повертає об'єкт Position (з координатами lat та lon)
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Перевіряємо, чи взагалі увімкнений GPS на телефоні
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS вимкнено. Увімкніть локацію.');
    }

    // Перевіряємо дозволи
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Якщо немає, запитуємо у користувача
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Дозвіл на локацію відхилено');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Дозвіл відхилено назавжди. Змініть це в налаштуваннях.');
    }

    // Якщо все ок - беремо координати.
    // desiredAccuracy: LocationAccuracy.high - для точного місцезнаходження
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}