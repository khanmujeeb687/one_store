import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_store/one_store.dart';
import 'package:one_store/persistable.dart';

void main() {
  group('OneStore', () {
    test('initial state is set correctly', () {
      final store = OneStore<StoreClass>(StoreClass(10));
      expect(store.state?.value, equals(10));
    });

    test('setState updates the value', () {
      final store = OneStore<StoreClass>(StoreClass(0));
      store.setState(StoreClass(5));
      expect(store.state?.value, equals(5));
    });

    test('getState returns selected value', () {
      final store = OneStore<StoreClass>(StoreClass(10));
      final count = store.getState((state) => state?.value);
      expect(count, equals(10));
    });

    testWidgets('createComponent builds widget with initial state',
        (tester) async {
      final store = OneStore<StoreClass>(StoreClass(1));

      final widget = MaterialApp(
        home: store.createComponent<StoreClass>(
          (state) => state ?? StoreClass(0),
          (context, value) => Text('Value: ${value.value}', textDirection: TextDirection.ltr),
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Value: 1'), findsOneWidget);
    });

    testWidgets('createComponent rebuilds when selected value changes',
        (tester) async {
      final store = OneStore<StoreClass>(StoreClass(0));
      int buildCount = 0;

      final widget = MaterialApp(
        home: store.createComponent<StoreClass>(
          (state) => state ?? StoreClass(0),
          (context, value) {
            buildCount++;
            return Text('Count: ${value.value}', textDirection: TextDirection.ltr);
          },
        ),
      );

      await tester.pumpWidget(widget);
      expect(find.text('Count: 0'), findsOneWidget);
      expect(buildCount, equals(1));

      // Update the store and trigger rebuild
      store.setState(StoreClass(1));
      await tester.pumpAndSettle();

      expect(find.text('Count: 1'), findsOneWidget);
      expect(buildCount, equals(2));
    });

    testWidgets('does not rebuild if selector output is unchanged',
        (tester) async {
      final store = OneStore<StoreClass>(StoreClass(1));
      int buildCount = 0;

      final widget = MaterialApp(
        home: store.createComponent<int>(
          (state) => state?.value ?? 0, // only depends on 'a'
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
      store.setState(StoreClass(1));
      await tester.pumpAndSettle();

      // No rebuild should happen
      expect(buildCount, equals(1));

      // Now actually change 'a'
      store.setState(StoreClass(2));
      await tester.pumpAndSettle();

      expect(find.text('A: 2'), findsOneWidget);
      expect(buildCount, equals(2));
    });
  });
}



class StoreClass extends Persistable<StoreClass> {
  final int value;

  StoreClass(this.value);

  @override
  Map<String, dynamic> toJson() {
    return {'value': value};
  }
  
  @override
  StoreClass fromString(String jsonString) {
    final jsonMap = jsonDecode(jsonString);
    return StoreClass(jsonMap['value']);
  }
}