import 'package:replay/src/event_store/event_store.dart';

class InMemoryEventStore<TEvent> implements EventStore<TEvent> {
  final List<TEvent> _events;

  InMemoryEventStore([Iterable<TEvent>? initialEvents])
    : _events = [...?initialEvents];

  @override
  Iterable<TEvent> get iterable => _events;

  @override
  void append(TEvent event) {
    _events.add(event);
  }
}
