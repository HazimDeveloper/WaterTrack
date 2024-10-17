import 'package:flutter/material.dart';
import 'package:google_map_hakas_version/pages/home_pages.dart';
import 'dart:math' as math;

import 'package:google_map_hakas_version/pages/login_page.dart';

class WaterDropSplashScreen extends StatefulWidget {
  const WaterDropSplashScreen({super.key});

  @override
  _WaterDropSplashScreenState createState() => _WaterDropSplashScreenState();
}

class _WaterDropSplashScreenState extends State<WaterDropSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _splashAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _dropAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _splashAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[300]!, Colors.blue[700]!],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: WaterDropPainter(_dropAnimation.value, _splashAnimation.value),
                  child: Container(),
                );
              },
            ),
            const Center(
              child: Text(
                'WaterApp',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterDropPainter extends CustomPainter {
  final double dropValue;
  final double splashValue;

  WaterDropPainter(this.dropValue, this.splashValue);

  @override
  void paint(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final splashPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Draw water drop
    final dropPath = Path();
    double dropY = size.height * 0.6 * dropValue;
    dropPath.addOval(Rect.fromCircle(
      center: Offset(size.width / 2, dropY),
      radius: 10,
    ));
    canvas.drawPath(dropPath, dropPaint);

    // Draw splash
    if (splashValue > 0) {
      final splashPath = Path();
      for (int i = 0; i < 8; i++) {
        double angle = i * math.pi / 4;
        double splashRadius = 30 * splashValue;
        double x = size.width / 2 + splashRadius * math.cos(angle);
        double y = size.height * 0.6 + splashRadius * math.sin(angle);
        splashPath.addOval(Rect.fromCircle(
          center: Offset(x, y),
          radius: 5 * splashValue,
        ));
      }
      canvas.drawPath(splashPath, splashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}