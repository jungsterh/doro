import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'animated_flip_digit.dart';
import 'flip_digit.dart';

class FlipClock extends StatelessWidget {
  final Duration elapsed;
  final bool useFlip;

  const FlipClock({
    super.key,
    required this.elapsed,
    this.useFlip = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : const Color(0xFFE8EAF0);
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final separatorColor =
        isDark ? AppColors.darkAccent : AppColors.lightAccent;

    final hours = _pad(elapsed.inHours);
    final minutes = _pad(elapsed.inMinutes.remainder(60));
    final seconds = _pad(elapsed.inSeconds.remainder(60));

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        // Fall back to screen size if constraints are unbounded (first-frame edge case)
        final maxW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : mq.size.width;
        // Subtract horizontal safe-area insets so digits stay within the safe area
        final safeWidth = maxW - mq.padding.left - mq.padding.right;
        final availableWidth = safeWidth * 0.9;
        final sizeByWidth = availableWidth / 5.26;
        final sizeByHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight / 1.6
            : double.infinity;
        final size = sizeByWidth < sizeByHeight ? sizeByWidth : sizeByHeight;

        Widget pair(String value) => useFlip
            ? AnimatedFlipDigitPair(
                value: value,
                digitSize: size,
                textColor: textColor,
                backgroundColor: bg,
              )
            : FlipDigitPair(
                value: value,
                digitSize: size,
                textColor: textColor,
                backgroundColor: bg,
              );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            pair(hours),
            _Separator(color: separatorColor, size: size),
            pair(minutes),
            _Separator(color: separatorColor, size: size),
            pair(seconds),
          ],
        );
      },
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _Separator extends StatelessWidget {
  final Color color;
  final double size;

  const _Separator({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: size * 0.08,
            height: size * 0.08,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(height: size * 0.2),
          Container(
            width: size * 0.08,
            height: size * 0.08,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
