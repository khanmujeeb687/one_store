class OneStore<T> {
  T? _state;

  OneStore(T? initialState) {
    this._state = initialState;
  }

  T? getState() => _state;

  void setState(T? newState) {
    _state = newState;
  }
}
