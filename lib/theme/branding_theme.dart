import 'package:flutter/material.dart';

import '../models/app_appearance.dart';

ThemeData buildAppTheme({
  required AppAppearance appearance,
  required Brightness brightness,
}) {
  final seed = parseHexColor(appearance.accentSeedHex) ?? Colors.deepPurpleAccent;
  final baseScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final customFontColor = parseHexColor(appearance.fontColorHex);
  final scheme = customFontColor == null
      ? baseScheme
      : baseScheme.copyWith(
          onSurface: customFontColor,
          onSurfaceVariant: Color.lerp(customFontColor, baseScheme.onSurfaceVariant, 0.35) ??
              customFontColor,
        );

  final url = appearance.backgroundImageUrl?.trim();
  final hasImage = url != null && url.isNotEmpty;

  final scaffoldBg = hasImage
      ? Colors.transparent
      : (parseHexColor(appearance.scaffoldBackgroundHex) ?? scheme.surface);

  final baseTheme = ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,
    useMaterial3: true,
  );
  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    primaryTextTheme: baseTheme.primaryTextTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
  );
}

/// Capa detrás del [MaterialApp] para imagen de fondo y velo de lectura.
class AppearanceBackground extends StatelessWidget {
  final AppAppearance appearance;
  final Widget child;

  const AppearanceBackground({
    super.key,
    required this.appearance,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final url = appearance.backgroundImageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;
    if (!hasImage) return child;

    final overlay = appearance.backgroundOverlayOpacity.clamp(0.0, 1.0);
    final fallbackColor = Theme.of(context).colorScheme.surface;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => ColoredBox(color: fallbackColor),
          ),
        ),
        if (overlay > 0)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: overlay),
            ),
          ),
        child,
      ],
    );
  }
}
