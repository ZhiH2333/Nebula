import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nebula/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Wrap in ProviderScope for Riverpod
    await tester.pumpWidget(
      const ProviderScope(
        child: NebulaApp(),
      ),
    );

    // Verify that the login screen appears (since not logged in)
    expect(find.text('登录 Nebula'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
