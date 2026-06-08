import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.backgroundColor,
    this.borderColor,
    this.width,
    this.height,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    Color bg;
    Color border;

    if (isPrimary) {
      bg = accent.withValues(alpha: 0.85);
      border = accent;
    } else {
      bg = backgroundColor ??
          (isDark ? AppColors.glassDark : AppColors.glassLight);
      border = borderColor ??
          (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight);
    }

    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final TextStyle? textStyle;

  const GlassPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
    this.height = 56,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: onPressed,
      width: width,
      height: height,
      isPrimary: true,
      child: Text(
        label,
        style: textStyle ??
            Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
      ),
    );
  }
}
