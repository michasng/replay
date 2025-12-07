import 'package:replay/src/event_storage/event_storage.dart';

class InMemoryEventStorage<TEvent> implements EventStorage<TEvent> {
  final List<TEvent> _events;

  InMemoryEventStorage([Iterable<TEvent>? initialEvents])
    : _events = [...?initialEvents];

  @override
  Iterable<TEvent> get iterable => _events;

  @override
  void append(TEvent event) {
    _events.add(event);
  }
}
