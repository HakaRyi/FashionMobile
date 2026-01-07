import 'package:flutter/material.dart';
import 'package:fashion_mobile/screens/home_screen.dart';
import 'package:fashion_mobile/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.background),
      ),
      home: const HomeScreen(),
    );
  }
}
