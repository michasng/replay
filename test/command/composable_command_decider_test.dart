import 'package:replay/replay.dart';
import 'package:test/test.dart';

import 'command_decider_mock.dart';

class State {}

abstract interface class Event {}

class Event0 implements Event {}

abstract interface class Command {}

class Command0 implements Command {}

class Command1 implements Command {}

class Command2 implements Command {}

void main() {
  group('ComposableCommandDecider', () {
    late ComposableCommandDecider<Command, Event, State>
    composableCommandDecider;

    setUp(() {
      composableCommandDecider = ComposableCommandDecider();
    });

    group('register', () {
      test(
        'when registering multiple deciders for the same command type, throws',
        () {
          composableCommandDecider.register<Command0>(
            CommandDeciderMock<Command0, Event, State>(),
          );

          expect(
            () => composableCommandDecider.register<Command0>(
              CommandDeciderMock<Command0, Event, State>(),
            ),
            throwsA(
              allOf(
                isArgumentError,
                predicate(
                  (ArgumentError e) =>
                      e.message ==
                      "Another value is already registered for 'Command0'.",
                ),
              ),
            ),
          );
        },
      );

      test(
        "when registering deciders for multiple command types, doesn't throw",
        () {
          composableCommandDecider.register<Command0>(
            CommandDeciderMock<Command0, Event, State>(),
          );
          composableCommandDecider.register<Command1>(
            CommandDeciderMock<Command1, Event, State>(),
          );
        },
      );
    });

    group('decide', () {
      final command0DeciderMock = CommandDeciderMock<Command0, Event, State>();
      final command1DeciderMock = CommandDeciderMock<Command1, Event, State>();

      setUp(() {
        command0DeciderMock.clear();
        composableCommandDecider
          ..register<Command0>(command0DeciderMock)
          ..register<Command1>(command1DeciderMock);
      });

      test(
        'given a known command type, calls only the decider registered for that type',
        () {
          final command = Command0();
          final state = State();
          final expectedEvents = [Event0(), Event0()];
          command0DeciderMock.onDecide = (_, _) => expectedEvents;

          final events = composableCommandDecider.decide(command, state);

          expect(command0DeciderMock.calls, [(command, state)]);
          expect(events, expectedEvents);
          expect(command1DeciderMock.calls, isEmpty);
        },
      );

      test('given an unknown command type, throws', () {
        final command = Command2();
        final state = State();

        expect(
          () => composableCommandDecider.decide(command, state),
          throwsA(
            allOf(
              isArgumentError,
              predicate(
                (ArgumentError e) =>
                    e.message == "No value is registered for 'Command2'.",
              ),
            ),
          ),
        );
      });
    });
  });
}
