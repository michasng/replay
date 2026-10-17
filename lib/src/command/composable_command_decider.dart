import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/internal/typed_registry.dart';

class ComposableCommandDecider<TCommand, TEvent, TState>
    implements CommandDecider<TCommand, TEvent, TState> {
  final TypedRegistry<TCommand, CommandDecider<TCommand, TEvent, TState>>
  _registry = TypedRegistry();

  /// Registers a decider for commands of type [TConcreteCommand], including subtypes.
  /// When several registrations match a command, the first registered wins.
  void register<TConcreteCommand extends TCommand>(
    CommandDecider<TConcreteCommand, TEvent, TState> commandDecider,
  ) {
    _registry.register<TConcreteCommand>(commandDecider);
  }

  @override
  Iterable<TEvent> decide(TCommand command, TState state) {
    return _registry.resolve(command).decide(command, state);
  }
}
