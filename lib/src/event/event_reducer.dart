abstract interface class EventReducer<TEvent, TState> {
  /// Returns a new state with the event applied to it.
  /// The original state is not modified.
  TState reduce(TEvent event, TState state);
}
