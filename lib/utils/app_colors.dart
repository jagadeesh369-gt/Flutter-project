import 'package:flutter/material.dart';

/// Centralized color definitions for the FoodBridge application.
/// Follows modern Material 3 palette centered around Forest Green.
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF237A57);
  static const Color primaryDark = Color(0xFF165239);
  static const Color primaryLight = Color(0xFF389B72);
  static const Color secondary = Color(0xFFE8F5EC);
  static const Color secondaryDark = Color(0xFFC8E6D3);

  // Background and Surfaces
  static const Color backgroundLight = Color(0xFFF8FAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF121815);
  static const Color surfaceDark = Color(0xFF1B2320);
  static const Color cardDark = Color(0xFF222C28);
  static const Color dividerDark = Color(0xFF2E3D37);

  // Typography
  static const Color textPrimaryLight = Color(0xFF1A202C);
  static const Color textSecondaryLight = Color(0xFF718096);
  static const Color textMutedLight = Color(0xFFA0AEC0);

  static const Color textPrimaryDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textMutedDark = Color(0xFF718096);

  // Status & Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);

  static const Color warning = Color(0xFFE65100);
  static const Color warningContainer = Color(0xFFFFF3E0);

  static const Color danger = Color(0xFFC62828);
  static const Color dangerContainer = Color(0xFFFFEBEE);

  static const Color info = Color(0xFF0277BD);
  static const Color infoContainer = Color(0xFFE1F5FE);

  // Category Accent Colors for visual recognition
  static const Color catRiceGrains = Color(0xFFD97706);
  static const Color catVegetables = Color(0xFF16A34A);
  static const Color catFruits = Color(0xFFEA580C);
  static const Color catDairy = Color(0xFF0284C7);
  static const Color catPackaged = Color(0xFF9333EA);
  static const Color catPulses = Color(0xFFB45309);
  static const Color catOther = Color(0xFF475569);
}
