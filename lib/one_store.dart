import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OneStore<T> {
  final ValueNotifier<T?> _notifier;

  OneStore(T? initialState) : _notifier = ValueNotifier(initialState);

  T? get state => _notifier.value;

  void setState(T newState) {
    _notifier.value = newState;
  }

  R getState<R>(R Function(T? state) selector) => selector(_notifier.value);

  /// Rebuilds only if selector output changes
  Widget createComponent<K>(
    K Function(T? state) selector,
    Widget Function(BuildContext context, K data) builder,
  ) {
    return _SelectorBuilder<T, K>(
      listenable: _notifier,
      selector: selector,
      builder: builder,
    );
  }
}

class _SelectorBuilder<T, K> extends StatefulWidget {
  final ValueListenable<T?> listenable;
  final K Function(T? state) selector;
  final Widget Function(BuildContext context, K data) builder;

  const _SelectorBuilder({
    required this.listenable,
    required this.selector,
    required this.builder,
  });

  @override
  State<_SelectorBuilder<T, K>> createState() => _SelectorBuilderState<T, K>();
}

class _SelectorBuilderState<T, K> extends State<_SelectorBuilder<T, K>> {
  late K _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selector(widget.listenable.value);
    widget.listenable.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    final newValue = widget.selector(widget.listenable.value);
    if (newValue != _selectedValue) {
      setState(() => _selectedValue = newValue);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _selectedValue);
}
