import 'package:flutter/material.dart';

/// Design system — "Soft Navy + Pastels": a light, rounded-card aesthetic.
/// Token names are kept from the previous dark theme for source continuity
/// (`ember` = the primary interactive color, `canvas` = the color that
/// contrasts with it). Values are now light.
class AppColors {
  static const canvas = Color(0xFFF3EEF0); // soft dusty app background
  static const surface = Color(0xFFFFFFFF); // cards
  static const surfaceHigh = Color(0xFFFBF7F9); // raised / inputs
  static const ember = Color(0xFF2B358C); // primary (buttons, active, icons)
  static const emberSoft = Color(0xFF3D49B0); // pressed / gradient end
  static const accent = Color(0xFFF2889B); // coral — secondary pops
  static const protein = Color(0xFF34B98A); // mint (text-legible)
  static const carb = Color(0xFF8B79E0); // lavender (text-legible)
  static const fat = Color(0xFFE89A5C); // peach (text-legible)
  static const textHi = Color(0xFF1A1A22); // primary text (ink)
  static const textMid = Color(0xFF6B6B76); // secondary text
  static const textLow = Color(0xFFA6A2AC); // hints / disabled
  static const line = Color(0xFFE7E2E6); // hairline borders
  static const danger = Color(0xFFC62F3B); // destructive / error (AA on white)

  // Card / surface tokens (kept names; now light, opaque, non-frosted).
  static const glassFill = surface; // card fill
  static const glassFillHigh = surface; // nav / raised card fill
  static const glassStroke = line; // hairline
  static const glassHighlight = Color(0x00FFFFFF); // unused in light theme
}
