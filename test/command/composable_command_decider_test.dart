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

class Command1Sub extends Command1 {}

void main() {
  group('ComposableCommandDecider', () {
    final command0DeciderMock = CommandDeciderMock<Command0, Event, State>();
    final command1DeciderMock = CommandDeciderMock<Command1, Event, State>();
    late ComposableCommandDecider<Command, Event, State>
    composableCommandDecider;

    setUp(() {
      command0DeciderMock.calls.clear();
      command1DeciderMock.calls.clear();

      composableCommandDecider = ComposableCommandDecider()
        ..register<Command0>(command0DeciderMock);
    });

    group('register', () {
      test(
        'when registering another decider for the same command type, throws',
        () {
          expect(
            () => composableCommandDecider.register<Command0>(
              command0DeciderMock,
            ),
            throwsA(
              allOf(
                isArgumentError,
                predicate(
                  (ArgumentError e) =>
                      e.message ==
                      "Another value is already registered for 'Command0'",
                ),
              ),
            ),
          );
        },
      );

      test("when registering another decider for a different command type, doesn't throw", () {
        composableCommandDecider.register<Command1>(command1DeciderMock);
      });
    });

    group('decide', () {
      setUp(() {
        composableCommandDecider.register<Command1>(command1DeciderMock);
      });

      test('given a known command type, calls only the decider registered for that type', () {
        final command = Command1();
        final state = State();
        final expectedEvents = [Event0(), Event0()];
        command1DeciderMock.onDecide = (_, _) => expectedEvents;

        final events = composableCommandDecider.decide(command, state);

        expect(events, expectedEvents);
        expect(command0DeciderMock.calls, isEmpty);
        expect(command1DeciderMock.calls, [(command, state)]);
      });

      test('given an unknown command type, throws', () {
        final command = Command2();
        final state = State();

        expect(
          () => composableCommandDecider.decide(command, state),
          throwsA(
            allOf(
              isStateError,
              predicate(
                (StateError e) =>
                    e.message == "No value is registered for 'Command2'",
              ),
            ),
          ),
        );
      });

      test(
        'given a subtype of a registered command type, calls that decider',
        () {
          final command = Command1Sub();
          final state = State();
          command1DeciderMock.onDecide = (_, _) => [];

          composableCommandDecider.decide(command, state);

          expect(command1DeciderMock.calls, [(command, state)]);
        },
      );

      test('given overlapping registrations, the first registered wins', () {
        final broadMock = CommandDeciderMock<Command, Event, State>();
        final decider = ComposableCommandDecider<Command, Event, State>()
          ..register<Command1>(command1DeciderMock)
          ..register<Command>(broadMock);
        command1DeciderMock.onDecide = (_, _) => [];

        decider.decide(Command1(), State());
        decider.decide(Command2(), State());

        expect(command1DeciderMock.calls, hasLength(1));
        expect(broadMock.calls, hasLength(1));
      });
    });
  });
}
