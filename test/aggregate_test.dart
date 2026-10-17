import 'package:replay/replay.dart';
import 'package:test/test.dart';

import 'count_example.dart';

class _FailingEventStorage implements EventStorage<IncrementedEvent> {
  @override
  Stream<IncrementedEvent> readAll() => const Stream.empty();

  @override
  Future<void> appendAll(List<IncrementedEvent> events) =>
      Future.error(StateError('appendAll'));
}

typedef _CountAggregate =
    AggregateFullyGeneric<
      IncrementCommand,
      IncrementedEvent,
      CountState,
      IncrementOption
    >;

void main() {
  group('Aggregate', () {
    final optionFinderMock = createIncrementOptionFinderMock();
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
    late _CountAggregate aggregate;

    setUp(() {
      optionFinderMock.calls.clear();
      commandDeciderMock.calls.clear();
      eventReducerMock.calls.clear();
      onEventReducedCalls.clear();
    });

    void onEventReduced(
      IncrementedEvent event,
      CountState previousState,
      CountState updatedState,
    ) {
      onEventReducedCalls.add((event, previousState, updatedState));
    }

    Future<_CountAggregate> load([EventStorage<IncrementedEvent>? storage]) =>
        _CountAggregate.load<
          IncrementCommand,
          IncrementedEvent,
          CountState,
          IncrementOption
        >(
          initialState: initialState,
          optionFinder: optionFinderMock,
          commandDecider: commandDeciderMock,
          eventReducer: eventReducerMock,
          eventStorage: storage,
          onEventReduced: onEventReduced,
        );

    group('load', () {
      group('given stored events', () {
        final storedEvents = [IncrementedEvent(), IncrementedEvent()];
        final intermediateState = CountState(1);
        final finalState = CountState(2);

        setUp(() async {
          aggregate = await load(InMemoryEventStorage(storedEvents));
        });

        test('replays the events', () {
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

        test('keeps the event storage', () async {
          expect(await aggregate.eventStorage.readAll().toList(), storedEvents);
        });
      });

      group('given no event storage', () {
        setUp(() async {
          aggregate = await load();
        });

        test('starts empty in the initial state', () async {
          expect(await aggregate.eventStorage.readAll().toList(), isEmpty);
          expect(aggregate.currentState, initialState);
          expect(eventReducerMock.calls, isEmpty);
        });
      });
    });

    group('resume', () {
      final storedEvents = [IncrementedEvent(), IncrementedEvent()];
      final resumedState = CountState(100);

      setUp(() async {
        aggregate =
            _CountAggregate.resume<
              IncrementCommand,
              IncrementedEvent,
              CountState,
              IncrementOption
            >(
              state: resumedState,
              commandDecider: commandDeciderMock,
              eventReducer: eventReducerMock,
              eventStorage: InMemoryEventStorage(storedEvents),
              onEventReduced: onEventReduced,
            );
      });

      test('starts in the given state without replaying stored events', () {
        expect(aggregate.currentState, resumedState);
        expect(eventReducerMock.calls, isEmpty);
        expect(onEventReducedCalls, isEmpty);
      });

      test('appends new events after the stored events', () async {
        final state = await aggregate.process(IncrementCommand(1));

        expect(state, CountState(101));
        expect(await aggregate.eventStorage.readAll().toList(), [
          ...storedEvents,
          IncrementedEvent(),
        ]);
      });

      test(
        'given no event storage, starts with an empty in-memory one',
        () async {
          final resumed =
              _CountAggregate.resume<
                IncrementCommand,
                IncrementedEvent,
                CountState,
                IncrementOption
              >(
                state: resumedState,
                commandDecider: commandDeciderMock,
                eventReducer: eventReducerMock,
              );

          expect(await resumed.eventStorage.readAll().toList(), isEmpty);
        },
      );
    });

    group('findOptions', () {
      test('returns current options', () async {
        aggregate = await load();

        final options = aggregate.findOptions();

        expect(options.toList(), [IncrementOption()]);
        expect(optionFinderMock.calls, [initialState]);
      });

      test('given no option finder, returns no options', () async {
        final aggregateWithoutOptions =
            await _CountAggregate.load<
              IncrementCommand,
              IncrementedEvent,
              CountState,
              IncrementOption
            >(
              initialState: initialState,
              commandDecider: commandDeciderMock,
              eventReducer: eventReducerMock,
            );

        expect(aggregateWithoutOptions.findOptions(), isEmpty);
      });
    });

    group('process', () {
      setUp(() async {
        aggregate = await load();
      });

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
              throw InvalidCommandException('Command is invalid');
        });

        tearDown(() {
          commandDeciderMock.onDecide = originalOnDecide;
        });

        test('throws without committing any events', () async {
          await expectLater(
            aggregate.process(command),
            throwsA(
              allOf(
                isA<InvalidCommandException>(),
                predicate(
                  (InvalidCommandException e) =>
                      e.message == 'Command is invalid',
                ),
              ),
            ),
          );

          expect(commandDeciderMock.calls, [(command, initialState)]);
          expect(eventReducerMock.calls, isEmpty);
          expect(onEventReducedCalls, isEmpty);
          expect(await aggregate.eventStorage.readAll().toList(), isEmpty);
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
              throw ArgumentError('Event cannot be reduced');
            }
            return originalOnReduce!.call(event, state);
          };
        });

        tearDown(() {
          eventReducerMock.onReduce = originalOnReduce;
        });

        test('throws without committing any events', () async {
          await expectLater(
            aggregate.process(command),
            throwsA(
              allOf(
                isArgumentError,
                predicate(
                  (ArgumentError e) => e.message == 'Event cannot be reduced',
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
          expect(await aggregate.eventStorage.readAll().toList(), isEmpty);
          expect(aggregate.currentState, initialState);
        });
      });

      group('when appending the events fails', () {
        test('leaves state unchanged', () async {
          final failingAggregate = await load(_FailingEventStorage());

          await expectLater(
            failingAggregate.process(IncrementCommand(2)),
            throwsStateError,
          );

          expect(failingAggregate.currentState, initialState);
          expect(onEventReducedCalls, isEmpty);
        });
      });

      group('when onEventReduced throws', () {
        test('state and storage are both fully updated', () async {
          final failingAggregate =
              await _CountAggregate.load<
                IncrementCommand,
                IncrementedEvent,
                CountState,
                IncrementOption
              >(
                initialState: initialState,
                commandDecider: commandDeciderMock,
                eventReducer: eventReducerMock,
                onEventReduced: (_, _, _) => throw StateError('callback'),
              );

          await expectLater(
            failingAggregate.process(IncrementCommand(2)),
            throwsStateError,
          );

          expect(failingAggregate.currentState, CountState(2));
          expect(
            await failingAggregate.eventStorage.readAll().toList(),
            hasLength(2),
          );
        });
      });

      group('when the command is valid and nothing throws', () {
        final command = IncrementCommand(2);
        final events = [IncrementedEvent(), IncrementedEvent()];
        final intermediateState = CountState(1);
        final finalState = CountState(2);

        test('processes the command', () async {
          final state = await aggregate.process(command);

          expect(state, finalState);
          expect(commandDeciderMock.calls, [(command, initialState)]);
          expect(eventReducerMock.calls, [
            (events[0], initialState),
            (events[1], intermediateState),
          ]);
          expect(onEventReducedCalls, [
            (events[0], initialState, intermediateState),
            (events[1], intermediateState, finalState),
          ]);
          expect(await aggregate.eventStorage.readAll().toList(), events);
          expect(aggregate.currentState, finalState);
        });

        test('a reloaded aggregate reproduces the state', () async {
          await aggregate.process(command);

          final reloaded = await load(aggregate.eventStorage);

          expect(reloaded.currentState, finalState);
        });
      });
    });
  });
}
