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

  TState _stateSnapshot;
  TState get currentState => _stateSnapshot;

  EventStorage<TEvent> _eventStorage;
  EventStorage<TEvent> get eventStorage => _eventStorage;

  AggregateFullyGeneric({
    required TState initialState,
    this._optionFinder,
    required this._commandDecider,
    required this._eventReducer,
    EventStorage<TEvent>? eventStorage,
    bool replayStoredEvents = false,
    this._onEventReduced,
  }) : _stateSnapshot = initialState,
       _eventStorage = eventStorage ?? InMemoryEventStorage() {
    if (replayStoredEvents) _replayStoredEvents();
  }

  void replay({
    required TState initialState,
    required EventStorage<TEvent> eventStorage,
  }) {
    _stateSnapshot = initialState;
    _eventStorage = eventStorage;
    _replayStoredEvents();
  }

  void _replayStoredEvents() {
    final events = _eventStorage.iterable;
    if (events.isNotEmpty) {
      for (final event in events) {
        final previousState = _stateSnapshot;
        _stateSnapshot = _eventReducer.reduce(event, _stateSnapshot);

        _onEventReduced?.call(event, previousState, _stateSnapshot);
      }
    }
  }

  Iterable<TOption> findOptions() {
    return _optionFinder?.find(_stateSnapshot) ?? [];
  }

  TState process(TCommand command) {
    final events = _commandDecider.decide(command, _stateSnapshot);

    final reductions = <({TEvent event, TState updatedState})>[];
    var runningState = _stateSnapshot;
    for (final event in events) {
      runningState = _eventReducer.reduce(event, runningState);
      reductions.add((event: event, updatedState: runningState));
    }

    // commit transaction: storage first, then state, then callbacks
    for (final reduction in reductions) {
      _eventStorage.append(reduction.event);
    }

    final previousState = _stateSnapshot;
    _stateSnapshot = runningState;

    var callbackPreviousState = previousState;
    for (final reduction in reductions) {
      _onEventReduced?.call(
        reduction.event,
        callbackPreviousState,
        reduction.updatedState,
      );
      callbackPreviousState = reduction.updatedState;
    }

    return _stateSnapshot;
  }
}
