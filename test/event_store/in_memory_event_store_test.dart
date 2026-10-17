import 'package:replay/replay.dart';
import 'package:test/test.dart';

class Event {}

void main() {
  group('InMemoryEventStorage', () {
    late InMemoryEventStorage<Event> eventStorage;

    setUp(() {
      eventStorage = InMemoryEventStorage();
    });

    test('initially, readAll is empty', () {
      expect(eventStorage.readAll(), emitsDone);
    });

    test('given initial events, readAll yields them in order', () {
      final events = [Event(), Event()];

      eventStorage = InMemoryEventStorage(events);

      expect(eventStorage.readAll(), emitsInOrder([...events, emitsDone]));
    });

    group('after events have been appended', () {
      final firstEvents = [Event(), Event()];
      final secondEvents = [Event()];

      setUp(() async {
        await eventStorage.appendAll(firstEvents);
        await eventStorage.appendAll(secondEvents);
      });

      test('readAll yields all events in append order', () {
        expect(
          eventStorage.readAll(),
          emitsInOrder([...firstEvents, ...secondEvents, emitsDone]),
        );
      });

      test('readAll can be read multiple times', () async {
        final expected = [...firstEvents, ...secondEvents];

        expect(await eventStorage.readAll().toList(), expected);
        expect(await eventStorage.readAll().toList(), expected);
      });
    });
  });
}
