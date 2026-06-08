import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class GlassDecoration {
  GlassDecoration._();

  static BoxDecoration dark({
    double borderRadius = 16,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.glassDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorderDark,
        width: 1,
      ),
    );
  }

  static BoxDecoration light({
    double borderRadius = 16,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.glassLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorderLight,
        width: 1,
      ),
    );
  }

  static BoxDecoration themed(
    BuildContext context, {
    double borderRadius = 16,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? dark(
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
          )
        : light(
            borderRadius: borderRadius,
            backgroundColor: backgroundColor,
            borderColor: borderColor,
          );
  }
}

class GlassWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double sigmaX;
  final double sigmaY;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassWidget({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.sigmaX = 6,
    this.sigmaY = 6,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.glassDark : AppColors.glassLight);
    final border = borderColor ??
        (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);

    return RepaintBoundary(
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: border, width: 1),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
