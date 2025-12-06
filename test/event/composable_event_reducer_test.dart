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
    final event0ReducerMock = EventReducerMock<Event0, State>();
    final event1ReducerMock = EventReducerMock<Event1, State>();
    late ComposableEventReducer<Event, State> composableEventReducer;

    setUp(() {
      event0ReducerMock.clear();
      event1ReducerMock.clear();

      composableEventReducer = ComposableEventReducer({
        Event0: event0ReducerMock,
      });
    });

    group('register', () {
      test(
        'when registering another reducer for the same event type, throws',
        () {
          expect(
            () => composableEventReducer.register<Event0>(event0ReducerMock),
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
        "when registering another reducer for a different event type, doesn't throw",
        () {
          composableEventReducer.register<Event1>(event1ReducerMock);
        },
      );
    });

    group('reduce', () {
      setUp(() {
        composableEventReducer.register<Event1>(event1ReducerMock);
      });

      test(
        'given a known event type, calls only the reducer registered for that type',
        () {
          final event = Event1();
          final state = State();
          final expectedState = State();
          event1ReducerMock.onReduce = (_, _) => expectedState;

          final events = composableEventReducer.reduce(event, state);

          expect(events, expectedState);
          expect(event0ReducerMock.calls, isEmpty);
          expect(event1ReducerMock.calls, [(event, state)]);
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
