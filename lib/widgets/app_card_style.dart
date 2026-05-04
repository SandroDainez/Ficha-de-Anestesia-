import 'package:flutter/material.dart';

class AppCardStyle {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));
  static const BorderRadius headerRadius = BorderRadius.all(
    Radius.circular(13),
  );
  static const BoxShadow shadow = BoxShadow(
    color: Color(0x0D17324D),
    blurRadius: 14,
    offset: Offset(0, 6),
  );

  static BoxDecoration decoration({
    required Color background,
    required Color borderColor,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: radius,
      border: Border.all(color: borderColor),
      boxShadow: const [shadow],
    );
  }
}
