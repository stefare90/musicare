import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color.fromARGB(255, 193, 128, 255);
  static const Color primaryVariant = Color.fromARGB(255, 235, 204, 251);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF181818);
  static const Color darkSurfaceCard = Color(0xFF242424);
  static const Color darkSurfaceHighlight = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);

  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF1F3F4);
  static const Color lightSurfaceHighlight = Color(0xFFE8EAED);
  static const Color lightTextPrimary = Color(0xFF1F1F1F);
  static const Color lightTextSecondary = Color(0xFF5F6368);

  static const Color error = Color.fromARGB(255, 255, 113, 113);
  static const Color onError = Color.fromARGB(255, 255, 255, 255);
}
