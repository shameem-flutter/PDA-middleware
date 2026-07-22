import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pda/main.dart';
import 'package:pda/screens/splashscreen.dart';

void main() {
  testWidgets('App root initializes correctly with SplashScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PDA(),
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // Flush pending 2-second SplashScreen navigation timer
    await tester.pump(const Duration(seconds: 3));
  });
}
