import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

abstract class Persistable<T> {
  Map<String, dynamic> toJson();

  @override
  String toString() => jsonEncode(toJson()).toString();

  T fromString(String jsonString);

  static bool _isWriting = false;

  Future<void> saveStringLocally(String value) async {
    while (_isWriting) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    _isWriting = true;
    try {
      final file = File('local_data.txt');
      await file.writeAsString(value);
    } finally {
      _isWriting = false;
    }
  }

  Future<String?> readStringLocally() async {
    final file = File('local_data.txt');
    if (await file.exists()) {
      final contents = await file.readAsString();
      return contents;
    } else {
      debugPrint('No saved data found.');
      return null;
    }
  }
}
