import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/internal/typed_registry.dart';

class ComposableCommandDecider<TCommand, TEvent, TState>
    implements CommandDecider<TCommand, TEvent, TState> {
  final TypedRegistry<CommandDecider<TCommand, TEvent, TState>> _registry =
      TypedRegistry();

  void register<TConcreteCommand extends TCommand>(
    CommandDecider<TConcreteCommand, TEvent, TState> commandDecider,
  ) {
    _registry.register(TConcreteCommand, commandDecider);
  }

  @override
  Iterable<TEvent> decide(TCommand command, TState state) {
    final commandDecider = _registry.resolve(command.runtimeType);

    return commandDecider.decide(command, state);
  }
}
