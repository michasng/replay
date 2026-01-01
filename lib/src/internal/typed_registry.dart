/// A registry for storing and retrieving instances by their type.
class TypedRegistry<T> {
  final Map<Type, T> _entries;

  TypedRegistry([Map<Type, T>? entries]) : _entries = entries ?? {};

  void register(Type type, T value) {
    if (_entries.containsKey(type)) {
      throw ArgumentError("Another value is already registered for '$type'");
    }

    _entries[type] = value;
  }

  T resolve(Type type) {
    final value = _entries[type];
    if (value == null) {
      throw ArgumentError("No value is registered for '$type'");
    }

    return value;
  }

  Iterable<T> resolveAll() {
    return _entries.values;
  }
}
