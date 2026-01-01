import 'package:replay/src/internal/typed_registry.dart';
import 'package:replay/src/option/option_finder.dart';

class ComposableOptionFinder<TOption, TState>
    implements OptionFinder<TOption, TState> {
  final TypedRegistry<OptionFinder<TOption, TState>> _registry;

  ComposableOptionFinder([
    Map<Type, OptionFinder<TOption, TState>>? finderByOptionType,
  ]) : _registry = TypedRegistry(finderByOptionType);

  void register<TConcreteOption extends TOption>(
    OptionFinder<TConcreteOption, TState> finder,
  ) {
    _registry.register(TConcreteOption, finder);
  }

  @override
  Iterable<TOption> find(TState state) sync* {
    for (final finder in _registry.resolveAll()) {
      yield* finder.find(state);
    }
  }
}
