import 'package:replay/src/event_storage/event_storage.dart';

/// Keeps events in memory only.
class InMemoryEventStorage<TEvent> implements EventStorage<TEvent> {
  final List<TEvent> _events;

  InMemoryEventStorage([Iterable<TEvent>? initialEvents])
    : _events = [...?initialEvents];

  @override
  Stream<TEvent> readAll() => Stream.fromIterable([..._events]);

  @override
  Future<void> appendAll(List<TEvent> events) async {
    _events.addAll(events);
  }
}
