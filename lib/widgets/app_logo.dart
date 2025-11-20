import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool circular;

  const AppLogo({super.key, this.size = 120, this.circular = false});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      "assets/duwitku_logo_cropped.png",
      fit: BoxFit.contain,
      height: size,
    );

    if (circular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        padding: EdgeInsets.all(size * 0.15),
        child: logo,
      );
    }

    return SizedBox(height: size, child: logo);
  }
}
