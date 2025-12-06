import 'package:replay/replay.dart';

class CommandDeciderMock<TCommand, TEvent, TState>
    implements CommandDecider<TCommand, TEvent, TState> {
  final List<(TCommand command, TState state)> calls = [];
  Iterable<TEvent> Function(TCommand command, TState state)? onDecide;

  CommandDeciderMock([this.onDecide]);

  void clear() {
    calls.clear();
  }

  @override
  Iterable<TEvent> decide(TCommand command, TState state) {
    calls.add((command, state));
    return onDecide?.call(command, state) ?? [];
  }
}
