import 'package:replay/replay.dart';

class EventReducerMock<TEvent, TState> implements EventReducer<TEvent, TState> {
  final List<(TEvent event, TState state)> calls = [];
  TState Function(TEvent event, TState state)? onReduce;

  EventReducerMock([this.onReduce]);

  @override
  TState reduce(TEvent event, TState state) {
    calls.add((event, state));
    return onReduce?.call(event, state) ?? state;
  }
}
