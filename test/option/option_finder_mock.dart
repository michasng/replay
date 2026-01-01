import 'package:replay/replay.dart';

class OptionFinderMock<TOption, TState>
    implements OptionFinder<TOption, TState> {
  final List<TState> calls = [];
  Iterable<TOption> Function(TState state)? onFind;

  OptionFinderMock([this.onFind]);

  @override
  Iterable<TOption> find(TState state) {
    calls.add(state);
    return onFind?.call(state) ?? [];
  }
}
