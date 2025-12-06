import 'package:replay/replay.dart';
import 'package:replay/src/command/invalid_command_exception.dart';
import 'package:test/test.dart';

import 'count_example.dart';

void main() {
  group('Aggregate', () {
    final commandDeciderMock = createIncrementCommandDeciderMock();
    final eventReducerMock = createIncrementedEventReducerMock();
    final initialState = CountState(0);
    final List<
      (
        IncrementedEvent event,
        CountState previousState,
        CountState updatedState,
      )
    >
    onEventReducedCalls = [];
    late Aggregate<IncrementCommand, IncrementedEvent, CountState> aggregate;

    setUp(() {
      commandDeciderMock.clear();
      eventReducerMock.clear();
      onEventReducedCalls.clear();
    });

    void onEventReduced(
      IncrementedEvent event,
      CountState previousState,
      CountState updatedState,
    ) {
      onEventReducedCalls.add((event, previousState, updatedState));
    }

    group('when a custom event store is used with replay', () {
      final storedEvents = [IncrementedEvent(), IncrementedEvent()];
      final intermediateState = CountState(1);
      final finalState = CountState(2);

      setUp(() {
        aggregate = Aggregate(
          initialState: initialState,
          commandDecider: commandDeciderMock,
          eventReducer: eventReducerMock,
          eventStore: InMemoryEventStore(storedEvents),
          replayStoredEvents: true,
          onEventReduced: onEventReduced,
        );
      });

      test('event store is set', () {
        expect(aggregate.eventStore.iterable, storedEvents);
      });

      test('events are replayed', () {
        expect(eventReducerMock.calls, [
          (storedEvents[0], initialState),
          (storedEvents[1], intermediateState),
        ]);
        expect(onEventReducedCalls, [
          (storedEvents[0], initialState, intermediateState),
          (storedEvents[1], intermediateState, finalState),
        ]);
        expect(aggregate.currentState, finalState);
      });
    });

    group('when a custom event store is used without replay', () {
      final storedEvents = [IncrementedEvent(), IncrementedEvent()];

      setUp(() {
        aggregate = Aggregate(
          initialState: initialState,
          commandDecider: commandDeciderMock,
          eventReducer: eventReducerMock,
          eventStore: InMemoryEventStore(storedEvents),
          onEventReduced: onEventReduced,
        );
      });

      test('event store is set', () {
        expect(aggregate.eventStore.iterable, storedEvents);
      });

      test('events are not replayed', () {
        expect(eventReducerMock.calls, isEmpty);
        expect(onEventReducedCalls, isEmpty);
        expect(aggregate.currentState, initialState);
      });
    });

    group('when the default event store is used', () {
      setUp(() {
        aggregate = Aggregate(
          initialState: initialState,
          commandDecider: commandDeciderMock,
          eventReducer: eventReducerMock,
          onEventReduced: onEventReduced,
        );
      });

      test('event store is empty', () {
        expect(aggregate.eventStore.iterable, isEmpty);
      });

      test('events are not replayed', () {
        expect(eventReducerMock.calls, isEmpty);
        expect(onEventReducedCalls, isEmpty);
        expect(aggregate.currentState, initialState);
      });

      group('replay', () {
        final newInitialState = CountState(100);
        final storedEvents = [IncrementedEvent(), IncrementedEvent()];
        final intermediateState = CountState(101);
        final finalState = CountState(102);

        setUp(() {
          aggregate.replay(
            initialState: newInitialState,
            eventStore: InMemoryEventStore(storedEvents),
          );
        });

        test('event store is set', () {
          expect(aggregate.eventStore.iterable, storedEvents);
        });

        test('events are replayed', () {
          expect(eventReducerMock.calls, [
            (storedEvents[0], newInitialState),
            (storedEvents[1], intermediateState),
          ]);
          expect(onEventReducedCalls, [
            (storedEvents[0], newInitialState, intermediateState),
            (storedEvents[1], intermediateState, finalState),
          ]);
          expect(aggregate.currentState, finalState);
        });
      });

      group('process', () {
        group('when the command is invalid', () {
          final command = IncrementCommand(2);
          Iterable<IncrementedEvent> Function(
            IncrementCommand command,
            CountState state,
          )?
          originalOnDecide;

          setUp(() {
            originalOnDecide = commandDeciderMock.onDecide;
            commandDeciderMock.onDecide = (_, _) =>
                throw InvalidCommandException('Command is invalid.');
          });

          tearDown(() {
            commandDeciderMock.onDecide = originalOnDecide;
          });

          test('throws without committing any events', () {
            expect(
              () => aggregate.process(command),
              throwsA(
                allOf(
                  isA<InvalidCommandException>(),
                  predicate(
                    (InvalidCommandException e) =>
                        e.message == 'Command is invalid.',
                  ),
                ),
              ),
            );

            expect(commandDeciderMock.calls, [(command, initialState)]);
            expect(eventReducerMock.calls, isEmpty);
            expect(onEventReducedCalls, isEmpty);
            expect(aggregate.eventStore.iterable, isEmpty);
            expect(aggregate.currentState, initialState);
          });
        });

        group('when the command is valid but an event throws on reduction', () {
          final command = IncrementCommand(2);
          final events = [IncrementedEvent(), IncrementedEvent()];
          final intermediateState = CountState(1);

          CountState Function(IncrementedEvent event, CountState state)?
          originalOnReduce;

          setUp(() {
            originalOnReduce = eventReducerMock.onReduce;
            var onReduceCallCount = 0;
            eventReducerMock.onReduce = (event, state) {
              onReduceCallCount++;
              if (onReduceCallCount == 2) {
                throw ArgumentError('Event cannot be reduced.');
              }
              return originalOnReduce!.call(event, state);
            };
          });

          tearDown(() {
            eventReducerMock.onReduce = originalOnReduce;
          });

          test('throws without committing any events', () {
            expect(
              () => aggregate.process(command),
              throwsA(
                allOf(
                  isArgumentError,
                  predicate(
                    (ArgumentError e) =>
                        e.message == 'Event cannot be reduced.',
                  ),
                ),
              ),
            );

            expect(commandDeciderMock.calls, [(command, initialState)]);
            expect(eventReducerMock.calls, [
              (events[0], initialState),
              (events[1], intermediateState),
            ]);
            expect(onEventReducedCalls, isEmpty);
            expect(aggregate.eventStore.iterable, isEmpty);
            expect(aggregate.currentState, initialState);
          });
        });

        group('when the command is valid and nothing throws', () {
          final command = IncrementCommand(2);
          final events = [IncrementedEvent(), IncrementedEvent()];
          final intermediateState = CountState(1);
          final finalState = CountState(2);

          test('processes the command', () {
            aggregate.process(command);

            expect(commandDeciderMock.calls, [(command, initialState)]);
            expect(eventReducerMock.calls, [
              (events[0], initialState),
              (events[1], intermediateState),
            ]);
            expect(onEventReducedCalls, [
              (events[0], initialState, intermediateState),
              (events[1], intermediateState, finalState),
            ]);
            expect(aggregate.eventStore.iterable, events);
            expect(aggregate.currentState, finalState);
          });
        });
      });
    });
  });
}
