abstract interface class EventStorage<TEvent> {
  Iterable<TEvent> get iterable;
  void append(TEvent event);
}
