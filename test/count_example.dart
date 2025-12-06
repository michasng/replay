import 'command/command_decider_mock.dart';
import 'event/event_reducer_mock.dart';

class CountState {
  final int count;

  const CountState(this.count);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountState &&
          runtimeType == other.runtimeType &&
          count == other.count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => '$CountState(count: $count)';
}

class IncrementedEvent {
  const IncrementedEvent();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncrementedEvent && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  @override
  String toString() => '$IncrementedEvent()';
}

class IncrementCommand {
  final int increment;

  const IncrementCommand(this.increment);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncrementCommand &&
          runtimeType == other.runtimeType &&
          increment == other.increment;

  @override
  int get hashCode => increment.hashCode;

  @override
  String toString() => '$IncrementCommand(increment: $increment)';
}

CommandDeciderMock<IncrementCommand, IncrementedEvent, CountState>
createIncrementCommandDeciderMock() => CommandDeciderMock(
  (command, _) => [
    for (var i = 0; i < command.increment; i++) IncrementedEvent(),
  ],
);

EventReducerMock<IncrementedEvent, CountState>
createIncrementedEventReducerMock() =>
    EventReducerMock((_, state) => CountState(state.count + 1));
