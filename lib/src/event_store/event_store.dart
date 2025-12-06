abstract interface class EventStore<TEvent> {
  Iterable<TEvent> get iterable;
  void append(TEvent event);
}
