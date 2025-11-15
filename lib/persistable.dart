import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// A base class that enables model objects to be:
/// - Converted to/from JSON
/// - Saved and loaded from local storage
/// - Serialized safely with write locking
///
/// Your model (e.g., BigState) must implement:
///   Map<String, dynamic> toJson();
///   T fromString(String jsonString);
abstract class Persistable<T> {
  /// Convert the model to JSON. Implemented by child classes.
  Map<String, dynamic> toJson();

  /// JSON string representation of the model.
  /// This is what gets written to disk.
  @override
  String toString() => jsonEncode(toJson()).toString();

  /// Restore an object from a JSON string.
  /// Implemented by child classes.
  T fromString(String jsonString);

  /// A simple in-memory lock to prevent two writes happening at once.
  /// Prevents file corruption from overlapping asynchronous writes.
  static bool _isWriting = false;

  /// Saves the model's serialized JSON string to local storage.
  /// Ensures only one write happens at a time (simple async lock).
  ///
  /// Notes:
  /// - Blocks other writers via `_isWriting`
  /// - Writes atomically (one file write operation)
  /// - Overwrites a single file: local_data.txt
  Future<void> saveStringLocally(String value) async {
    // Wait until other write operations finish
    while (_isWriting) {
      await Future.delayed(Duration(milliseconds: 1));
    }

    _isWriting = true;
    try {
      final file = File('local_data.txt');

      // Write the JSON string to disk
      await file.writeAsString(value);
    } finally {
      // Release the lock even if an exception occurs
      _isWriting = false;
    }
  }

  /// Reads the saved JSON string from local storage.
  ///
  /// Returns:
  ///   - JSON string if file exists
  ///   - null if file does not exist
  Future<String?> readStringLocally() async {
    final file = File('local_data.txt');

    // If no saved state exists, return null (first-time run)
    if (!await file.exists()) {
      debugPrint('No saved data found.');
      return null;
    }

    // Read entire file contents
    final contents = await file.readAsString();
    return contents;
  }
}
