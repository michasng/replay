import 'package:replay/src/command/command_decider.dart';
import 'package:replay/src/event/event_reducer.dart';
import 'package:replay/src/event_storage/event_storage.dart';
import 'package:replay/src/event_storage/in_memory_event_storage.dart';
import 'package:replay/src/option/option_finder.dart';

typedef OnEventReduced<TEvent, TState> = void Function(
  TEvent event,
  TState previousState,
  TState updatedState,
);

/// Sets / Omits optional generic parameters.
/// Mainly exists for backwards compatibility.
typedef Aggregate<TCommand, TEvent, TState> =
    AggregateFullyGeneric<TCommand, TEvent, TState, dynamic>;

class AggregateFullyGeneric<TCommand, TEvent, TState, TOption> {
  final OptionFinder<TOption, TState>? _optionFinder;
  final CommandDecider<TCommand, TEvent, TState> _commandDecider;
  final EventReducer<TEvent, TState> _eventReducer;
  final OnEventReduced<TEvent, TState>? _onEventReduced;

  TState _state;
  TState get currentState => _state;

  final EventStorage<TEvent> eventStorage;

  AggregateFullyGeneric._({
    required TState initialState,
    required this._optionFinder,
    required this._commandDecider,
    required this._eventReducer,
    required this.eventStorage,
    required this._onEventReduced,
  }) : _state = initialState;

  /// Creates an aggregate and replays all events of [eventStorage] onto [initialState].
  /// Without an [eventStorage], events are kept in memory.
  static Future<AggregateFullyGeneric<TCommand, TEvent, TState, TOption>>
  load<TCommand, TEvent, TState, TOption>({
    required TState initialState,
    OptionFinder<TOption, TState>? optionFinder,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStorage<TEvent>? eventStorage,
    OnEventReduced<TEvent, TState>? onEventReduced,
  }) async {
    final aggregate =
        AggregateFullyGeneric<TCommand, TEvent, TState, TOption>._(
          initialState: initialState,
          optionFinder: optionFinder,
          commandDecider: commandDecider,
          eventReducer: eventReducer,
          eventStorage: eventStorage ?? InMemoryEventStorage(),
          onEventReduced: onEventReduced,
        );
    await aggregate._replayStoredEvents();
    return aggregate;
  }

  /// Creates an aggregate that starts in [state] without reading [eventStorage].
  /// Only events appended from now on are applied.
  ///
  /// [state] should already reflect the events in [eventStorage].
  /// Otherwise loading the same storage later yields a different state.
  static AggregateFullyGeneric<TCommand, TEvent, TState, TOption>
  resume<TCommand, TEvent, TState, TOption>({
    required TState state,
    OptionFinder<TOption, TState>? optionFinder,
    required CommandDecider<TCommand, TEvent, TState> commandDecider,
    required EventReducer<TEvent, TState> eventReducer,
    EventStorage<TEvent>? eventStorage,
    OnEventReduced<TEvent, TState>? onEventReduced,
  }) => AggregateFullyGeneric<TCommand, TEvent, TState, TOption>._(
    initialState: state,
    optionFinder: optionFinder,
    commandDecider: commandDecider,
    eventReducer: eventReducer,
    eventStorage: eventStorage ?? InMemoryEventStorage(),
    onEventReduced: onEventReduced,
  );

  Future<void> _replayStoredEvents() async {
    await for (final event in eventStorage.readAll()) {
      final previousState = _state;
      _state = _eventReducer.reduce(event, _state);

      _onEventReduced?.call(event, previousState, _state);
    }
  }

  Iterable<TOption> findOptions() {
    return _optionFinder?.find(_state) ?? [];
  }

  /// Decides [command], stores the resulting events with a single
  /// [EventStorage.appendAll] and only then updates the state.
  Future<TState> process(TCommand command) async {
    final events = _commandDecider.decide(command, _state);

    final reductions = <({TEvent event, TState updatedState})>[];
    var runningState = _state;
    for (final event in events) {
      runningState = _eventReducer.reduce(event, runningState);
      reductions.add((event: event, updatedState: runningState));
    }

    // commit transaction: storage first, then state, then callbacks
    await eventStorage.appendAll([
      for (final reduction in reductions) reduction.event,
    ]);

    final previousState = _state;
    _state = runningState;

    var callbackPreviousState = previousState;
    for (final reduction in reductions) {
      _onEventReduced?.call(
        reduction.event,
        callbackPreviousState,
        reduction.updatedState,
      );
      callbackPreviousState = reduction.updatedState;
    }

    return _state;
  }
}
