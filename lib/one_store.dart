import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:one_store/persistable.dart';

/// A lightweight state container with:
/// - Persistable state (load + save)
/// - Selector-based widget rebuilds
/// - Minimal boilerplate + Flutter-friendly API
class OneStore<T extends Persistable<T>> {
  /// Internal notifier that triggers updates to selector widgets.
  final ValueNotifier<T?> _notifier;

  /// Creates the store with an initial state.
  /// The state is *not* auto-loaded; call `await store.load()` manually.
  OneStore(
    T initialState,
  ) : _notifier = ValueNotifier(initialState);

  /// Loads state from local storage by calling Persistable.readStringLocally().
  Future<void> load() async => _loadFromLocal();

  /// Current state value (nullable because initial load is async).
  T? get state => _notifier.value;

  /// Reads the string representation from disk and restores the object.
  Future<void> _loadFromLocal() async {
    final savedString = await _notifier.value?.readStringLocally();
    if (savedString != null) {
      _notifier.value = _notifier.value?.fromString(savedString);
    }
  }

  /// Sets a new state and notifies listeners.
  void setState(T newState) {
    _notifier.value = newState;
  }

  /// Applies a selector to the current state and returns the derived value.
  R getState<R>(R Function(T? state) selector) => selector(_notifier.value);

  /// Called when the component using this store is disposed.
  /// Saves the current state to local storage.
  void _onDestroy() {
    _notifier.value?.saveStringLocally(_notifier.value.toString());
  }

  /// Returns a widget that listens only to changes in the selected value.
  ///
  /// The selector runs every time the state changes, but the widget only
  /// rebuilds when the selector result is different from the previous one.
  ///
  /// Example:
  ///   store.createComponent((s) => s.counter, (context, value) => Text('$value'));
  Widget createComponent<K>(
    K Function(T? state) selector,
    Widget Function(BuildContext context, K data) builder,
  ) {
    return _SelectorBuilder<T, K>(
      listenable: _notifier,
      selector: selector,
      builder: builder,
      onDestroy: _onDestroy,
    );
  }
}

/// Stateful selector widget that rebuilds only when the derived value changes.
class _SelectorBuilder<T, K> extends StatefulWidget {
  final ValueListenable<T?> listenable;
  final K Function(T? state) selector;
  final Widget Function(BuildContext context, K data) builder;
  final void Function() onDestroy;

  const _SelectorBuilder({
    required this.listenable,
    required this.selector,
    required this.builder,
    required this.onDestroy,
  });

  @override
  State<_SelectorBuilder<T, K>> createState() => _SelectorBuilderState<T, K>();
}

class _SelectorBuilderState<T, K> extends State<_SelectorBuilder<T, K>> {
  /// Stores the last computed selector value to compare changes.
  late K _selectedValue;

  @override
  void initState() {
    super.initState();

    // Compute the initial selector result.
    _selectedValue = widget.selector(widget.listenable.value);

    // Subscribe to changes from the store’s ValueNotifier.
    widget.listenable.addListener(_onStateChanged);
  }

  /// Called whenever the underlying state changes.
  /// Only triggers rebuild if the selected value actually changed.
  void _onStateChanged() {
    final newValue = widget.selector(widget.listenable.value);

    // Only rebuild if selector output changed.
    if (newValue != _selectedValue) {
      setState(() => _selectedValue = newValue);
    }
  }

  @override
  void dispose() {
    // Remove the listener to avoid memory leaks.
    widget.listenable.removeListener(_onStateChanged);

    // Persist state when the last dependent widget is removed.
    widget.onDestroy();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _selectedValue);
}
