import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/internal/typed_registry.dart';

class ComposableEventReducer<TEvent, TState>
    implements EventReducer<TEvent, TState> {
  final TypedRegistry<TEvent, EventReducer<TEvent, TState>> _registry =
      TypedRegistry();

  /// Registers a reducer for events of type [TConcreteEvent], including subtypes.
  /// When several registrations match an event, the first registered wins.
  void register<TConcreteEvent extends TEvent>(
    EventReducer<TConcreteEvent, TState> eventReducer,
  ) {
    _registry.register<TConcreteEvent>(eventReducer);
  }

  @override
  TState reduce(TEvent event, TState state) {
    return _registry.resolve(event).reduce(event, state);
  }
}
