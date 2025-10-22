import 'package:flutter/material.dart';

class OneStore<T> {
  T? _state;

  OneStore(T? initialState) {
    this._state = initialState;
  }

  R getState<R>(Function(T? state) selector) => selector(_state);

  Widget createComponent<K>(
    BuildContext context,
    K Function(T? state) selector,
    Function(BuildContext context, K data) builder,
  ) {
    K data = selector(this._state);
    return builder(context, data);
  }
}
