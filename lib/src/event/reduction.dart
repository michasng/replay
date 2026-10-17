/// Records that [event] turned [previousState] into [state].
final class Reduction<TEvent, TState>({
  required final TEvent event,
  required final TState previousState,
  required final TState state,
}) {}
