import 'package:replay/replay.dart';
import 'package:test/test.dart';

class Event {}

void main() {
  group('InMemoryEventStorage', () {
    late InMemoryEventStorage<Event> eventStorage;

    setUp(() {
      eventStorage = InMemoryEventStorage();
    });

    test('initially, iterable is empty', () {
      expect(eventStorage.iterable, isEmpty);
    });

    group('after events have been appended', () {
      final events = [Event(), Event()];

      setUp(() {
        for (final event in events) {
          eventStorage.append(event);
        }
      });

      test('iterable returns all events in order', () {
        expect(eventStorage.iterable, events);
      });

      test('iterable can be read multiple times', () {
        expect(eventStorage.iterable, events);
        expect(eventStorage.iterable, events);
      });

      test('when a caller casts iterable to a list and mutates it, throws', () {
        // The cast is the scenario under test: callers must not be able to
        // mutate stored events by downcasting the exposed iterable.
        final list = eventStorage.iterable as List<Event>;

        expect(() => list.add(Event()), throwsUnsupportedError);
        expect(eventStorage.iterable, events);
      });
    });
  });
}
