/// Persists the events of a single aggregate.
abstract interface class EventStorage<TEvent> {
  /// Yields all stored events in the order they were appended.
  Stream<TEvent> readAll();

  /// Appends [events] in order.
  ///
  /// This is all-or-nothing: if the returned future completes with an error,
  /// none of the [events] were stored.
  Future<void> appendAll(List<TEvent> events);
}
