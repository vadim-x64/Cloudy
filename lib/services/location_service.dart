import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart'; // Імпортуємо наш LocationException

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Перевіряємо чи увімкнений GPS модуль (шторка на телефоні)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'gps_disabled',
        'GPS вимкнено. Увімкніть локацію для визначення погоди.',
      );
    }

    // 2. Перевіряємо дозволи додатку
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Якщо ще не запитували або відхилили 1 раз - питаємо
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'permission_denied',
          'Дозвіл на локацію відхилено. Без нього автоматичний пошук не працюватиме.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Користувач натиснув "Більше не питати"
      throw LocationException(
        'permission_denied_forever',
        'Дозвіл відхилено назавжди. Перейдіть у налаштування додатку, щоб дозволити доступ.',
      );
    }

    // Якщо все супер - беремо координати
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
