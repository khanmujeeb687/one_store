import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_store/one_store.dart';

void main() {
  group('OneStore', () {
    test('initial state is set correctly', () {
      final store = OneStore<int>(10);
      expect(store.state, equals(10));
    });

    test('setState updates the value', () {
      final store = OneStore<int>(0);
      store.setState(5);
      expect(store.state, equals(5));
    });

    test('getState returns selected value', () {
      final store = OneStore<Map<String, dynamic>>({'count': 10});
      final count = store.getState((state) => state?['count']);
      expect(count, equals(10));
    });

    testWidgets('createComponent builds widget with initial state',
        (tester) async {
      final store = OneStore<int>(1);

      final widget = MaterialApp(
        home: store.createComponent<int>(
          (state) => state ?? 0,
          (context, value) => Text('Value: $value', textDirection: TextDirection.ltr),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Value: 1'), findsOneWidget);
    });

    testWidgets('createComponent rebuilds when selected value changes',
        (tester) async {
      final store = OneStore<int>(0);
      int buildCount = 0;

      final widget = MaterialApp(
        home: store.createComponent<int>(
          (state) => state ?? 0,
          (context, value) {
            buildCount++;
            return Text('Count: $value', textDirection: TextDirection.ltr);
          },
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Count: 0'), findsOneWidget);
      expect(buildCount, equals(1));

      // Update the store and trigger rebuild
      store.setState(1);
      await tester.pumpAndSettle();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(buildCount, equals(2));
    });

    testWidgets('does not rebuild if selector output is unchanged',
        (tester) async {
      final store = OneStore<Map<String, dynamic>>({'a': 1, 'b': 2});
      int buildCount = 0;

      final widget = MaterialApp(
        home: store.createComponent<int>(
          (state) => state?['a'] ?? 0, // only depends on 'a'
          (context, value) {
            buildCount++;
            return Text('A: $value', textDirection: TextDirection.ltr);
          },
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('A: 1'), findsOneWidget);
      expect(buildCount, equals(1));

      // Change unrelated field ('b'), selector result is still 1
      store.setState({'a': 1, 'b': 3});
      await tester.pumpAndSettle();

      // No rebuild should happen
      expect(buildCount, equals(1));

      // Now actually change 'a'
      store.setState({'a': 2, 'b': 3});
      await tester.pumpAndSettle();

      expect(find.text('A: 2'), findsOneWidget);
      expect(buildCount, equals(2));
    });
  });
}
