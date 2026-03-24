import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
  });

  static const semanticLabel = 'Putaway logo';
  static const assetPath = 'assets/images/app_icon_master.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
