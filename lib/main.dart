import 'package:flutter/material.dart';
import 'package:google_map_hakas_version/pages/water_splash_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Access Tracker',
      
      home: WaterDropSplashScreen(),
    );
  }
}

