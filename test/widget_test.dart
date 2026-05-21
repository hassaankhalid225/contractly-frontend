// Basic smoke test: ensures the app boots without throwing.
//
// Heavier integration tests should mock the API layer / storage and live
// alongside the relevant feature module.

import 'package:contractly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Contractly boots without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ContractlyApp()));
    // Pump once; we don't drain timers because notifications/storage init
    // are async and expected to be in-flight.
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
