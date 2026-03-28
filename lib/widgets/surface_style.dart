import 'package:flutter/material.dart';

class SurfaceStyle {
  static List<BoxShadow> cardShadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 24,
          spreadRadius: -10,
          offset: Offset(0, 12),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x1A0F2A22),
        blurRadius: 24,
        spreadRadius: -10,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x120F2A22),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ];
  }

  static Border cardBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return Border.all(color: scheme.outline.withValues(alpha: 0.24));
    }
    return Border.all(color: Colors.white.withValues(alpha: 0.58));
  }
}
