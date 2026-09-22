import 'package:flutter/material.dart';

/// App Color Palette defined in the PRD:
/// Navy, Orange Accent, and Pastel Yellow Highlights
class AppColors {
  // Primary Navy Shades
  static const Color primaryNavy = Color(0xFF0F172A);      // #0F172A (Main Navy)
  static const Color primaryNavyDark = Color(0xFF020617);  // #020617 (Dark Navy)
  static const Color primaryNavyLight = Color(0xFF1E293B); // #1E293B (Lighter Navy)
  static const Color navyBorder = Color(0xFF334155);

  // Accent & Secondary
  static const Color accentOrange = Color(0xFFF97316);     // #F97316 (CTA / Active State)
  static const Color accentOrangeLight = Color(0xFFFFEDD5);// #FFEDD5 (Light Orange Chip)
  static const Color accentOrangeDark = Color(0xFFEA580C);

  // Pastel Yellow Highlights
  static const Color pastelYellow = Color(0xFFFEF08A);     // #FEF08A (Open Nota Badge / Highlight)
  static const Color pastelYellowLight = Color(0xFFFEF9C3);// #FEF9C3 (Surface Highlight)
  static const Color pastelYellowDark = Color(0xFFCA8A04);

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF8FAFC);       // #F8FAFC (App Background)
  static const Color surface = Color(0xFFFFFFFF);          // #FFFFFF (Cards & Sheets)
  static const Color surfaceMuted = Color(0xFFF1F5F9);     // #F1F5F9 (Input / Divider)
  static const Color textDark = Color(0xFF1E293B);         // #1E293B (Body Text)
  static const Color textMuted = Color(0xFF64748B);        // #64748B (Subtitle Text)
  static const Color border = Color(0xFFE2E8F0);

  // Status indicators
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0EA5E9);
}
