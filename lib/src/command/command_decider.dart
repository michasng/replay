import 'package:replay/src/command/invalid_command_exception.dart';

abstract interface class CommandDecider<TCommand, TEvent, TState> {
  /// Validates a command against the state to decide which events need to be reduced to reach the desired state.
  ///
  /// Throws an [InvalidCommandException] when the command is invalid.
  /// Otherwise returns events that need to be reduced in sequence on the state to fulfill the command.
  Iterable<TEvent> decide(TCommand command, TState state);
}
