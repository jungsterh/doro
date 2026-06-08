import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlipDigit extends StatelessWidget {
  final String digit;
  final double size;
  final Color textColor;
  final Color backgroundColor;

  const FlipDigit({
    super.key,
    required this.digit,
    this.size = 80,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF1C1C1E),
  });

  @override
  Widget build(BuildContext context) {
    final width = size * 0.75;
    final height = size * 1.6;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: GoogleFonts.orbitron(
          fontSize: size * 0.72,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class FlipDigitPair extends StatelessWidget {
  final String value;
  final double digitSize;
  final Color textColor;
  final Color backgroundColor;

  const FlipDigitPair({
    super.key,
    required this.value,
    this.digitSize = 80,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF1C1C1E),
  });

  @override
  Widget build(BuildContext context) {
    final d1 = value.isNotEmpty ? value[0] : '0';
    final d2 = value.length > 1 ? value[1] : '0';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlipDigit(
          digit: d1,
          size: digitSize,
          textColor: textColor,
          backgroundColor: backgroundColor,
        ),
        SizedBox(width: digitSize * 0.05),
        FlipDigit(
          digit: d2,
          size: digitSize,
          textColor: textColor,
          backgroundColor: backgroundColor,
        ),
      ],
    );
  }
}
