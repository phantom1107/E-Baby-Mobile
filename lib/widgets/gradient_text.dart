import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  const GradientText(
    this.text, {
    super.key,
    required this.colors,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}
