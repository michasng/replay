import 'dart:async';

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
    late _CountAggregate aggregate;

    setUp(() {
      optionFinderMock.calls.clear();
      commandDeciderMock.calls.clear();
      eventReducerMock.calls.clear();
    });

    Future<
      List<(IncrementedEvent event, CountState previousState, CountState state)>
    >
    collectReductions(_CountAggregate aggregate) => aggregate.events
        .map(
          (reduction) =>
              (reduction.event, reduction.previousState, reduction.state),
        )
        .toList();

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
          expect(aggregate.currentState, finalState);
        });

        test('does not notify about replayed events', () async {
          final reductions = collectReductions(aggregate);

          await aggregate.close();

          expect(await reductions, isEmpty);
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
            );
      });

      test('starts in the given state without replaying stored events', () {
        expect(aggregate.currentState, resumedState);
        expect(eventReducerMock.calls, isEmpty);
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
          final reductions = collectReductions(aggregate);

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
          await aggregate.close();

          expect(commandDeciderMock.calls, [(command, initialState)]);
          expect(eventReducerMock.calls, isEmpty);
          expect(await reductions, isEmpty);
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
          final reductions = collectReductions(aggregate);

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
          await aggregate.close();

          expect(commandDeciderMock.calls, [(command, initialState)]);
          expect(eventReducerMock.calls, [
            (events[0], initialState),
            (events[1], intermediateState),
          ]);
          expect(await reductions, isEmpty);
          expect(await aggregate.eventStorage.readAll().toList(), isEmpty);
          expect(aggregate.currentState, initialState);
        });
      });

      group('when appending the events fails', () {
        test('leaves state unchanged', () async {
          final failingAggregate = await load(_FailingEventStorage());
          final reductions = collectReductions(failingAggregate);

          await expectLater(
            failingAggregate.process(IncrementCommand(2)),
            throwsStateError,
          );
          await failingAggregate.close();

          expect(failingAggregate.currentState, initialState);
          expect(await reductions, isEmpty);
        });
      });

      group('when a listener throws', () {
        test(
          'state, storage and the processed result are unaffected',
          () async {
            final listenerErrors = <Object>[];
            runZonedGuarded(
              () =>
                  aggregate.events.listen((_) => throw StateError('listener')),
              (error, _) => listenerErrors.add(error),
            );

            final state = await aggregate.process(IncrementCommand(2));
            await aggregate.close();

            expect(state, CountState(2));
            expect(aggregate.currentState, CountState(2));
            expect(
              await aggregate.eventStorage.readAll().toList(),
              hasLength(2),
            );
            expect(listenerErrors, [isStateError, isStateError]);
          },
        );
      });

      group('when commands overlap', () {
        test('each decides against the state left by the previous', () async {
          final first = aggregate.process(IncrementCommand(1));
          final second = aggregate.process(IncrementCommand(2));

          expect(await first, CountState(1));
          expect(await second, CountState(3));
          expect(commandDeciderMock.calls, [
            (IncrementCommand(1), initialState),
            (IncrementCommand(2), CountState(1)),
          ]);
        });

        test('a rejected command does not block the next one', () async {
          final originalOnDecide = commandDeciderMock.onDecide;
          final acceptingOnDecide =
              createIncrementCommandDeciderMock().onDecide;
          commandDeciderMock.onDecide = (command, state) {
            if (command == IncrementCommand(0)) {
              throw InvalidCommandException('Command is invalid');
            }
            return acceptingOnDecide?.call(command, state) ?? [];
          };
          addTearDown(() => commandDeciderMock.onDecide = originalOnDecide);

          final rejected = aggregate.process(IncrementCommand(0));
          final accepted = aggregate.process(IncrementCommand(2));

          await expectLater(rejected, throwsA(isA<InvalidCommandException>()));
          expect(await accepted, CountState(2));
        });
      });

      group('when the command is valid and nothing throws', () {
        final command = IncrementCommand(2);
        final events = [IncrementedEvent(), IncrementedEvent()];
        final intermediateState = CountState(1);
        final finalState = CountState(2);

        test('processes the command', () async {
          final reductions = collectReductions(aggregate);

          final state = await aggregate.process(command);
          await aggregate.close();

          expect(state, finalState);
          expect(commandDeciderMock.calls, [(command, initialState)]);
          expect(eventReducerMock.calls, [
            (events[0], initialState),
            (events[1], intermediateState),
          ]);
          expect(await reductions, [
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

    group('close', () {
      setUp(() async {
        aggregate = await load();
      });

      test('finishes queued commands first', () async {
        final queued = aggregate.process(IncrementCommand(2));

        await aggregate.close();

        expect(aggregate.currentState, CountState(2));
        expect(await queued, CountState(2));
      });

      test('ends the event stream', () async {
        final reductions = collectReductions(aggregate);

        await aggregate.close();

        expect(await reductions, isEmpty);
      });

      test('rejects later commands', () async {
        await aggregate.close();

        await expectLater(
          aggregate.process(IncrementCommand(1)),
          throwsStateError,
        );
        expect(commandDeciderMock.calls, isEmpty);
      });
    });
  });
}
