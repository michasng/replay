import 'package:replay/replay.dart';
import 'package:test/test.dart';

class Event {}

void main() {
  group('InMemoryEventStore', () {
    late InMemoryEventStore<Event> eventStore;

    setUp(() {
      eventStore = InMemoryEventStore();
    });

    test('initially, iterable is empty', () {
      expect(eventStore.iterable, isEmpty);
    });

    group('after events have been appended', () {
      final events = [Event(), Event()];

      setUp(() {
        for (final event in events) {
          eventStore.append(event);
        }
      });

      test('iterable returns all events in order', () {
        expect(eventStore.iterable, events);
      });

      test('iterable can be read multiple times', () {
        expect(eventStore.iterable, events);
        expect(eventStore.iterable, events);
      });
    });
  });
}
