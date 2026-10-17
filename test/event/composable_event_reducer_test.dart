import 'package:replay/replay.dart';
import 'package:test/test.dart';

import 'event_reducer_mock.dart';

class State {}

abstract interface class Event {}

class Event0 implements Event {}

class Event1 implements Event {}

class Event2 implements Event {}

class Event1Sub extends Event1 {}

void main() {
  group('ComposableEventReducer', () {
    final event0ReducerMock = EventReducerMock<Event0, State>();
    final event1ReducerMock = EventReducerMock<Event1, State>();
    late ComposableEventReducer<Event, State> composableEventReducer;

    setUp(() {
      event0ReducerMock.calls.clear();
      event1ReducerMock.calls.clear();

      composableEventReducer = ComposableEventReducer()
        ..register<Event0>(event0ReducerMock);
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
                      "Another value is already registered for 'Event0'",
                ),
              ),
            ),
          );
        },
      );

      test("when registering another reducer for a different event type, doesn't throw", () {
        composableEventReducer.register<Event1>(event1ReducerMock);
      });
    });

    group('reduce', () {
      setUp(() {
        composableEventReducer.register<Event1>(event1ReducerMock);
      });

      test('given a known event type, calls only the reducer registered for that type', () {
        final event = Event1();
        final state = State();
        final expectedState = State();
        event1ReducerMock.onReduce = (_, _) => expectedState;

        final events = composableEventReducer.reduce(event, state);

        expect(events, expectedState);
        expect(event0ReducerMock.calls, isEmpty);
        expect(event1ReducerMock.calls, [(event, state)]);
      });

      test('given an unknown event type, throws', () {
        final event = Event2();
        final state = State();

        expect(
          () => composableEventReducer.reduce(event, state),
          throwsA(
            allOf(
              isStateError,
              predicate(
                (StateError e) =>
                    e.message == "No value is registered for 'Event2'",
              ),
            ),
          ),
        );
      });

      test(
        'given a subtype of a registered event type, calls that reducer',
        () {
          final event = Event1Sub();
          final state = State();
          event1ReducerMock.onReduce = (_, _) => state;

          composableEventReducer.reduce(event, state);

          expect(event1ReducerMock.calls, [(event, state)]);
        },
      );

      test('given overlapping registrations, the first registered wins', () {
        final broadMock = EventReducerMock<Event, State>();
        final reducer = ComposableEventReducer<Event, State>()
          ..register<Event1>(event1ReducerMock)
          ..register<Event>(broadMock);
        final state = State();
        event1ReducerMock.onReduce = (_, _) => state;
        broadMock.onReduce = (_, _) => state;

        reducer.reduce(Event1(), state);
        reducer.reduce(Event2(), state);

        expect(event1ReducerMock.calls, hasLength(1));
        expect(broadMock.calls, hasLength(1));
      });
    });
  });
}
