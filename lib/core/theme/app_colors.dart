import 'package:flutter/material.dart';

class AppColors {
  // Dark Backgrounds
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const surfaceLight = Color(0xFF334155);

  // Brand Colors
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryLight = Color(0xFF818CF8);
  static const secondary = Color(0xFF10B981); // Emerald

  // Text Colors
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);

  // Accents
  static const accent = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const glassOverlay = Color(0x33FFFFFF);

  const AppColors._();
}
