import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('BoostDriveMobileApp builds MaterialApp shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BoostDriveMobileApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
