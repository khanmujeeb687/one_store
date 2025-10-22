import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:one_store/one_store.dart';

void main() {
  group('OneStore', () {
    test('getState returns selected value for non-null state', () {
      final OneStore<int> store = OneStore<int>(42);

      final result = store.getState<int>((s) => s ?? -1);

      expect(result, 42);
    });

    test('getState handles null state', () {
      final OneStore<int> store = OneStore<int>(null);

      final result = store.getState<int>((s) => s ?? -1);

      expect(result, -1);
    });

    testWidgets('createComponent passes selected data to builder (non-null)',
        (WidgetTester tester) async {
      final OneStore<String> store = OneStore<String>('hello');

      // Host widget that uses createComponent in its build
      final host = MaterialApp(
        home: Builder(builder: (context) {
          return store.createComponent<String>(
            context,
            (s) => s ?? 'EMPTY',
            (ctx, data) => Text(data),
          );
        }),
      );

      await tester.pumpWidget(host);

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('createComponent passes selected data to builder (null)',
        (WidgetTester tester) async {
      final OneStore<String> store = OneStore<String>(null);

      final host = MaterialApp(
        home: Builder(builder: (context) {
          return store.createComponent<String>(
            context,
            (s) => s ?? 'EMPTY',
            (ctx, data) => Text(data),
          );
        }),
      );

      await tester.pumpWidget(host);

      expect(find.text('EMPTY'), findsOneWidget);
    });
  });
}
