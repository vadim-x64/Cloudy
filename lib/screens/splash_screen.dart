import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoMove;

  @override
  void initState() {
    super.initState();

    // Контролер для логотипу
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 1. Плавна поява (прозорість від 0 до 1)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 2. Анімація масштабу (виринання з відскоком)
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 3. Рух знизу вгору (спливання)
    _logoMove = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Запускаємо анімацію логотипу
    _logoController.forward();

    // Даємо трохи більше часу, щоб насолодитись красивою появою
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            // Плавне згасання сплеш-екрану
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4FC3F7),
      // Темний фон (залишив ваш колір)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Динамічний та плавний анімований логотип
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _logoMove.value),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/logo.png',
                width: 400, // Трохи збалансував розмір для елегантності
                height: 400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
