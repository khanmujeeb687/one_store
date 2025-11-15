import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:one_store/one_store.dart';
import 'package:one_store/persistable.dart';
import 'package:flutter/material.dart';

/// A large persistable state for stress testing
class BigState extends Persistable<BigState> {
  final List<int> numbers;

  BigState(this.numbers);

  @override
  Map<String, dynamic> toJson() => {
        'numbers': numbers,
      };

  @override
  BigState fromString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return BigState(List<int>.from(decoded['numbers']));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OneStore Load & Scalability Tests', () {
    const int bigSize = 5000000;

    // --- Benchmark with averages ---
    test('Benchmark average save/load time for large states', () async {
      final file = File('local_data.txt');
      if (await file.exists()) await file.delete();

      const int loops = 5;
      List<int> saveTimes = [];
      List<int> loadTimes = [];

      for (int i = 0; i < loops; i++) {
        final largeList = List<int>.generate(bigSize, (i) => i);
        final store = OneStore<BigState>(BigState(largeList));
        await store.load();
        (BigState(largeList));

        final saveStart = DateTime.now();
        await store.state!.saveStringLocally(store.state.toString());
        saveTimes.add(DateTime.now().difference(saveStart).inMilliseconds);

        final loadStart = DateTime.now();
        final loadedString = await store.state!.readStringLocally();
        store.state!.fromString(loadedString!);
        loadTimes.add(DateTime.now().difference(loadStart).inMilliseconds);
      }

      print(
          'Average SAVE time: ${saveTimes.reduce((a, b) => a + b) / loops} ms');
      print(
          'Average LOAD time: ${loadTimes.reduce((a, b) => a + b) / loops} ms');

      expect(saveTimes.length, loops);
      expect(loadTimes.length, loops);
    });

    // --- Widget test for selector build frequency ---
    testWidgets('Selector rebuild frequency test', (tester) async {
      int buildCount = 0;

      final store = OneStore<BigState>(BigState([0]));
      await store.load();

      await tester.pumpWidget(MaterialApp(
        home: store.createComponent<int>(
          (s) => s?.numbers.first ?? 0,
          (context, value) {
            buildCount++;
            return Text('Value: $value');
          },
        ),
      ));

      for (int i = 1; i <= 20; i++) {
        store.setState(BigState([i]));
        await tester.pump();
      }

      print('Selector builder rebuilt: $buildCount times');
      expect(buildCount <= 25, true);
    });

    // --- Parameterized tests for huge states ---
    final testSizes = [100000, 500000, 1000000];

    for (final size in testSizes) {
      test('Parameterized state size test: size=$size', () async {
        final file = File('local_data.txt');
        if (await file.exists()) await file.delete();

        final bigList = List<int>.generate(size, (i) => i);
        final store = OneStore<BigState>(BigState(bigList));
        await store.load();

        await store.state!.saveStringLocally(store.state.toString());
        final data = await store.state!.readStringLocally();
        final restored = store.state!.fromString(data!);

        expect(restored.numbers.length, size);
      });
    }

    test('Stress test multiple consecutive writes', () async {
      const int iterations = 50;
      final random = Random();
      final store = OneStore<BigState>(BigState([]));
      await store.load();

      for (int i = 0; i < iterations; i++) {
        final dynamicList =
            List<int>.generate(20000, (_) => random.nextInt(100000));
        store.setState(BigState(dynamicList));
        await store.state!.saveStringLocally(store.state.toString());
      }

      final file = File('local_data.txt');
      expect(await file.exists(), true);
    });
  });
}
