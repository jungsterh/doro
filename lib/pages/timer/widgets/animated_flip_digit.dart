import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single digit rendered as an animated split-flap card.
class AnimatedFlipDigit extends StatefulWidget {
  final String digit;
  final double size;
  final Color textColor;
  final Color backgroundColor;

  const AnimatedFlipDigit({
    super.key,
    required this.digit,
    this.size = 80,
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF1C1C1E),
  });

  @override
  State<AnimatedFlipDigit> createState() => _AnimatedFlipDigitState();
}

class _AnimatedFlipDigitState extends State<AnimatedFlipDigit>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _upperAnim; // 0 → π/2  (top half folds down)
  late Animation<double> _lowerAnim; // π/2 → 0  (bottom half unfolds)
  String _from = '';
  String _to = '';

  @override
  void initState() {
    super.initState();
    _from = widget.digit;
    _to = widget.digit;

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));

    _upperAnim = Tween<double>(begin: 0, end: math.pi / 2).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _lowerAnim = Tween<double>(begin: math.pi / 2, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedFlipDigit old) {
    super.didUpdateWidget(old);
    if (old.digit != widget.digit) {
      _from = old.digit;
      _to = widget.digit;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size * 0.75;
    final h = widget.size * 1.6;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final isFirstHalf = _ctrl.value < 0.5;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Static top half — positioned at y=0
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHalf(
                  digit: isFirstHalf ? _from : _to,
                  isTop: true,
                  w: w,
                  h: h,
                ),
              ),

              // Static bottom half — positioned at y=h/2
              Positioned(
                top: h / 2,
                left: 0,
                right: 0,
                child: _buildHalf(
                  digit: _to,
                  isTop: false,
                  w: w,
                  h: h,
                ),
              ),

              // Center divider line
              Positioned(
                top: h / 2 - 1,
                left: 0,
                right: 0,
                child: Container(height: 2, color: Colors.white),
              ),

              // Animated flap
              if (_ctrl.isAnimating)
                Positioned(
                  top: isFirstHalf ? 0 : h / 2,
                  left: 0,
                  right: 0,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateX(isFirstHalf
                          ? _upperAnim.value
                          : _lowerAnim.value),
                    alignment: isFirstHalf
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: _buildHalf(
                      digit: isFirstHalf ? _from : _to,
                      isTop: isFirstHalf,
                      w: w,
                      h: h,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHalf({
    required String digit,
    required bool isTop,
    required double w,
    required double h,
  }) {
    return ClipRect(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
            style: GoogleFonts.orbitron(
              fontSize: widget.size * 0.72,
              fontWeight: FontWeight.w600,
              color: widget.textColor,
              height: 1,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pair of two AnimatedFlipDigit for a two-char string like "05".
class AnimatedFlipDigitPair extends StatelessWidget {
  final String value;
  final double digitSize;
  final Color textColor;
  final Color backgroundColor;

  const AnimatedFlipDigitPair({
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
        AnimatedFlipDigit(
            digit: d1,
            size: digitSize,
            textColor: textColor,
            backgroundColor: backgroundColor),
        SizedBox(width: digitSize * 0.05),
        AnimatedFlipDigit(
            digit: d2,
            size: digitSize,
            textColor: textColor,
            backgroundColor: backgroundColor),
      ],
    );
  }
}
