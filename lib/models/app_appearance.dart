import 'package:flutter/material.dart';

/// Configuracion visual global leida desde Supabase (`app_appearance`).
class AppAppearance {
  final String? accentSeedHex;
  final String? scaffoldBackgroundHex;
  final String? fontColorHex;
  final String? backgroundImageUrl;
  final double backgroundOverlayOpacity;

  const AppAppearance({
    this.accentSeedHex,
    this.scaffoldBackgroundHex,
    this.fontColorHex,
    this.backgroundImageUrl,
    this.backgroundOverlayOpacity = 0.35,
  });

  static const AppAppearance fallback = AppAppearance();

  factory AppAppearance.fromJson(Map<String, dynamic> json) {
    final overlay = json['background_overlay_opacity'];
    double o = 0.35;
    if (overlay is num) {
      o = overlay.toDouble().clamp(0.0, 1.0);
    }
    return AppAppearance(
      accentSeedHex: _nullableString(json['accent_seed_color_hex']),
      scaffoldBackgroundHex: _nullableString(json['scaffold_background_color_hex']),
      fontColorHex: _nullableString(json['font_color_hex']),
      backgroundImageUrl: _nullableString(json['background_image_url']),
      backgroundOverlayOpacity: o,
    );
  }

  Map<String, dynamic> toRemoteUpsert() {
    return {
      'id': 1,
      'accent_seed_color_hex': _trimOrNull(accentSeedHex),
      'scaffold_background_color_hex': _trimOrNull(scaffoldBackgroundHex),
      'font_color_hex': _trimOrNull(fontColorHex),
      'background_image_url': _trimOrNull(backgroundImageUrl),
      'background_overlay_opacity': backgroundOverlayOpacity.clamp(0.0, 1.0),
    };
  }

  AppAppearance copyWith({
    String? accentSeedHex,
    String? scaffoldBackgroundHex,
    String? fontColorHex,
    String? backgroundImageUrl,
    double? backgroundOverlayOpacity,
  }) {
    return AppAppearance(
      accentSeedHex: accentSeedHex ?? this.accentSeedHex,
      scaffoldBackgroundHex: scaffoldBackgroundHex ?? this.scaffoldBackgroundHex,
      fontColorHex: fontColorHex ?? this.fontColorHex,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      backgroundOverlayOpacity: backgroundOverlayOpacity ?? this.backgroundOverlayOpacity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppAppearance &&
        other.accentSeedHex == accentSeedHex &&
        other.scaffoldBackgroundHex == scaffoldBackgroundHex &&
        other.fontColorHex == fontColorHex &&
        other.backgroundImageUrl == backgroundImageUrl &&
        other.backgroundOverlayOpacity == backgroundOverlayOpacity;
  }

  @override
  int get hashCode => Object.hash(
        accentSeedHex,
        scaffoldBackgroundHex,
        fontColorHex,
        backgroundImageUrl,
        backgroundOverlayOpacity,
      );

  static String? _nullableString(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static String? _trimOrNull(String? v) {
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
}

Color? parseHexColor(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) {
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
  if (s.length == 8) {
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
  return null;
}

bool isValidHexColor(String? input) {
  if (input == null || input.trim().isEmpty) return true;
  var s = input.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length != 6 && s.length != 8) return false;
  return int.tryParse(s, radix: 16) != null;
}
