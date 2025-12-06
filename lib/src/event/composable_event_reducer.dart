import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/internal/typed_registry.dart';

class ComposableEventReducer<TEvent, TState>
    implements EventReducer<TEvent, TState> {
  final TypedRegistry<EventReducer<TEvent, TState>> _registry;

  ComposableEventReducer([
    Map<Type, EventReducer<TEvent, TState>>? reducerByEventType,
  ]) : _registry = TypedRegistry(reducerByEventType);

  void register<TConcreteEvent extends TEvent>(
    EventReducer<TConcreteEvent, TState> eventReducer,
  ) {
    _registry.register(TConcreteEvent, eventReducer);
  }

  @override
  TState reduce(TEvent event, TState state) {
    final eventReducer = _registry.resolve(event.runtimeType);

    return eventReducer.reduce(event, state);
  }
}
