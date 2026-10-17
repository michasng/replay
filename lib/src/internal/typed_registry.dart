/// A registry of values by type.
///
/// Values are resolved by subtype matching, in registration order.
class TypedRegistry<TBase, TValue> {
  final List<({Type type, bool Function(TBase) matches, TValue value})>
  _entries = [];

  void register<T extends TBase>(TValue value) {
    if (_entries.any((entry) => entry.type == T)) {
      throw ArgumentError("Another value is already registered for '$T'");
    }

    _entries.add((type: T, matches: (base) => base is T, value: value));
  }

  /// Returns the first registered value whose type matches [base].
  TValue resolve(TBase base) {
    for (final entry in _entries) {
      if (entry.matches(base)) return entry.value;
    }

    throw StateError("No value is registered for '${base.runtimeType}'");
  }

  Iterable<TValue> resolveAll() {
    return _entries.map((entry) => entry.value);
  }
}
