import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0F0F0F)
        : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Top blank space
          const Expanded(flex: 2, child: SizedBox.expand()),

          // Logo in center
          Expanded(
            flex: 1,
            child: Center(
              child: Image.asset(
                'assets/images/doro_icon.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Bottom blank space
          const Expanded(flex: 2, child: SizedBox.expand()),
        ],
      ),
    );
  }
}
