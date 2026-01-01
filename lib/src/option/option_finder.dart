abstract interface class OptionFinder<TOption, TState> {
  /// Returns options, describing valid commands that could be processed with the same state.
  /// Implementations of this method must have no side-effects.
  Iterable<TOption> find(TState state);
}
