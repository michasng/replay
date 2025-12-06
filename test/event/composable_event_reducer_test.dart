import 'package:replay/replay.dart';
import 'package:test/test.dart';

import 'event_reducer_mock.dart';

class State {}

abstract interface class Event {}

class Event0 implements Event {}

class Event1 implements Event {}

class Event2 implements Event {}

void main() {
  group('ComposableEventReducer', () {
    late ComposableEventReducer<Event, State> composableEventReducer;

    setUp(() {
      composableEventReducer = ComposableEventReducer();
    });

    group('register', () {
      test(
        'when registering multiple reducers for the same event type, throws',
        () {
          composableEventReducer.register<Event0>(
            EventReducerMock<Event0, State>(),
          );

          expect(
            () => composableEventReducer.register<Event0>(
              EventReducerMock<Event0, State>(),
            ),
            throwsA(
              allOf(
                isArgumentError,
                predicate(
                  (ArgumentError e) =>
                      e.message ==
                      "Another value is already registered for 'Event0'.",
                ),
              ),
            ),
          );
        },
      );

      test(
        "when registering reducers for multiple event types, doesn't throw",
        () {
          composableEventReducer.register<Event0>(
            EventReducerMock<Event0, State>(),
          );
          composableEventReducer.register<Event1>(
            EventReducerMock<Event1, State>(),
          );
        },
      );
    });

    group('reduce', () {
      final event0ReducerMock = EventReducerMock<Event0, State>();
      final event1ReducerMock = EventReducerMock<Event1, State>();

      setUp(() {
        event0ReducerMock.clear();
        composableEventReducer
          ..register<Event0>(event0ReducerMock)
          ..register<Event1>(event1ReducerMock);
      });

      test(
        'given a known event type, calls only the reducer registered for that type',
        () {
          final event = Event0();
          final state = State();
          final expectedState = State();
          event0ReducerMock.onReduce = (_, _) => expectedState;

          final events = composableEventReducer.reduce(event, state);

          expect(event0ReducerMock.calls, [(event, state)]);
          expect(events, expectedState);
          expect(event1ReducerMock.calls, isEmpty);
        },
      );

      test('given an unknown event type, throws', () {
        final event = Event2();
        final state = State();

        expect(
          () => composableEventReducer.reduce(event, state),
          throwsA(
            allOf(
              isArgumentError,
              predicate(
                (ArgumentError e) =>
                    e.message == "No value is registered for 'Event2'.",
              ),
            ),
          ),
        );
      });
    });
  });
}
