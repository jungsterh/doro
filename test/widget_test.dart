import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doro/app.dart';
import 'package:doro/providers/auth_provider.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => AuthNotifier.unauthenticated()),
        ],
        child: const DoroApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
